"""Render a captured window like a macOS window screenshot.

Hyprland exposes no API that renders a window *with its server-side decorations* to an alpha
buffer: toplevel export explicitly excludes them, while workspace/output capture includes the
desktop background. The frame is therefore reconstructed from the values Hyprland does expose.

The values come from the running compositor: rounding, border size/colour, and shadow
enabled/sharp/range/power/scale/offset/colour. Each field falls back independently when
hyprctl is unavailable (tests, scripts outside the session).

The shadow uses Hyprland's own falloff from `src/render/shaders/glsl/shadow.glsl`:
`alpha = A * (1 - d / range) ** render_power` over the shadow's reach, so it is at full
colour alpha *at* the window edge and fades to nothing. A Gaussian blur cannot reproduce
that -- it peaks at half alpha and spreads the same darkness over twice the distance. The
one deliberate difference is `decoration:shadow:offset`: Hyprland moves the whole shadow box,
which leaves a band of full alpha under the window, while here the offset stretches the
reach on that side instead. Both look identical at offset 0.
"""

import json
import subprocess
from dataclasses import dataclass
from io import BytesIO

from PIL import Image, ImageChops, ImageDraw


@dataclass(frozen=True)
class WindowStyle:
    rounding: int = 12
    border_size: int = 1
    border_color: tuple[int, int, int, int] = (0, 0, 0, 55)
    shadow_enabled: bool = True
    shadow_sharp: bool = False
    shadow_range: int = 24
    shadow_power: int = 4
    shadow_scale: float = 1.0
    shadow_offset: tuple[int, int] = (0, 10)
    shadow_color: tuple[int, int, int, int] = (0, 0, 0, 90)


def _clamp(value: int) -> int:
    return max(0, min(255, value))


def parse_color(
    value: str | None, fallback: tuple[int, int, int, int]
) -> tuple[int, int, int, int]:
    """Hyprland colours: `rgba(RRGGBBAA)` in config, AARRGGBB hex from hyprctl."""
    try:
        return _parse_color(value, fallback)
    except (TypeError, ValueError):
        return fallback


def _parse_color(
    value: str | None, fallback: tuple[int, int, int, int]
) -> tuple[int, int, int, int]:
    if not value:
        return fallback

    # A gradient option is "rgba(...) rgba(...) 45deg": cut at the first ')' so the spaces
    # inside `rgba(0, 0, 0, 0.5)` survive. A plain hex gradient has no ')' at all.
    text = str(value).strip().lower()
    token = text[: text.index(")") + 1] if ")" in text else text.split()[0]
    if token.startswith("rgba(") and token.endswith(")"):
        inner = token[5:-1].strip()
        if "," in inner:
            parts = [float(part) for part in inner.split(",")]
            if len(parts) == 4:
                rgb = [
                    round(part * 255) if part <= 1 else round(part)
                    for part in parts[:3]
                ]
                alpha = round(parts[3] * 255) if parts[3] <= 1 else round(parts[3])
                return _clamp(rgb[0]), _clamp(rgb[1]), _clamp(rgb[2]), _clamp(alpha)
            return fallback
        # `rgba()` takes RRGGBBAA, unlike the bare hex hyprctl prints.
        if len(inner) == 8:
            return (
                int(inner[0:2], 16),
                int(inner[2:4], 16),
                int(inner[4:6], 16),
                int(inner[6:8], 16),
            )
        if len(inner) == 6:
            return int(inner[0:2], 16), int(inner[2:4], 16), int(inner[4:6], 16), 255
        return fallback
    if token.startswith("rgb(") and token.endswith(")"):
        parts = [float(part) for part in token[4:-1].split(",")]
        if len(parts) == 3:
            rgb = [round(part * 255) if part <= 1 else round(part) for part in parts]
            return _clamp(rgb[0]), _clamp(rgb[1]), _clamp(rgb[2]), 255

    token = token.lstrip("#")
    if token.startswith("0x"):
        token = token[2:]
    if len(token) == 8:
        return (
            int(token[2:4], 16),
            int(token[4:6], 16),
            int(token[6:8], 16),
            int(token[0:2], 16),
        )
    if len(token) == 6:
        return int(token[0:2], 16), int(token[2:4], 16), int(token[4:6], 16), 255
    return fallback


def _option(name: str) -> dict:
    return json.loads(
        subprocess.check_output(
            ["hyprctl", "-j", "getoption", name],
            text=True,
            stderr=subprocess.DEVNULL,
        )
    )


def _int(name: str, fallback: int) -> int:
    try:
        return int(_option(name).get("int", fallback))
    except (
        OSError,
        subprocess.SubprocessError,
        ValueError,
        KeyError,
        TypeError,
        json.JSONDecodeError,
    ):
        return fallback


def _float(name: str, fallback: float) -> float:
    try:
        return float(_option(name).get("float", fallback))
    except (
        OSError,
        subprocess.SubprocessError,
        ValueError,
        KeyError,
        TypeError,
        json.JSONDecodeError,
    ):
        return fallback


def _bool(name: str, fallback: bool) -> bool:
    try:
        return bool(_option(name).get("bool", fallback))
    except (
        OSError,
        subprocess.SubprocessError,
        ValueError,
        KeyError,
        TypeError,
        json.JSONDecodeError,
    ):
        return fallback


def _offset(name: str, fallback: tuple[int, int]) -> tuple[int, int]:
    try:
        data = _option(name)
        value = data.get("vec2")
        if isinstance(value, list) and len(value) == 2:
            return int(value[0]), int(value[1])
        custom = data.get("custom")
        if isinstance(custom, str):
            parts = custom.split()
            if len(parts) == 2:
                return int(parts[0]), int(parts[1])
    except (
        OSError,
        subprocess.SubprocessError,
        ValueError,
        KeyError,
        TypeError,
        json.JSONDecodeError,
    ):
        pass
    return fallback


def _color(name: str, fallback: tuple[int, int, int, int]) -> tuple[int, int, int, int]:
    try:
        data = _option(name)
        value = data.get("gradient") or data.get("color") or data.get("custom")
        return parse_color(value, fallback)
    except (
        OSError,
        subprocess.SubprocessError,
        ValueError,
        KeyError,
        TypeError,
        json.JSONDecodeError,
    ):
        return fallback


def style_from_hyprland() -> WindowStyle:
    """Read the live window manager's decoration values, falling back per field."""
    return WindowStyle(
        rounding=max(0, _int("decoration:rounding", 12)),
        border_size=max(0, _int("general:border_size", 1)),
        border_color=_color("general:col.active_border", (0, 0, 0, 55)),
        shadow_enabled=_bool("decoration:shadow:enabled", True),
        shadow_sharp=_bool("decoration:shadow:sharp", False),
        shadow_range=max(0, _int("decoration:shadow:range", 24)),
        shadow_power=max(1, min(4, _int("decoration:shadow:render_power", 4))),
        shadow_scale=min(1.0, max(0.0, _float("decoration:shadow:scale", 1.0))),
        shadow_offset=_offset("decoration:shadow:offset", (0, 10)),
        shadow_color=_color("decoration:shadow:color", (0, 0, 0, 90)),
    )


def _config_int(value, fallback: int) -> int:
    try:
        return int(value)
    except (TypeError, ValueError):
        return fallback


def style_from_config(config: dict | None = None) -> WindowStyle:
    """Use the Nexus window-frame settings, or follow Hyprland when followWm is on."""
    if not config or bool(config.get("followWm", True)):
        return style_from_hyprland()

    return WindowStyle(
        rounding=max(0, _config_int(config.get("rounding"), 12)),
        border_size=max(0, _config_int(config.get("borderSize"), 1)),
        border_color=parse_color(config.get("borderColor"), (0, 0, 0, 55)),
        shadow_enabled=bool(config.get("shadowEnabled", True)),
        shadow_range=max(0, _config_int(config.get("shadowRange"), 24)),
        shadow_power=max(1, min(4, _config_int(config.get("shadowPower"), 4))),
        shadow_offset=(
            _config_int(config.get("shadowOffsetX"), 0),
            _config_int(config.get("shadowOffsetY"), 10),
        ),
        shadow_color=parse_color(config.get("shadowColor"), (0, 0, 0, 90)),
    )


def _supersample(width: int, height: int) -> int:
    """Enough headroom to antialias edges without exploding memory on 4K/8K surfaces."""
    area = width * height
    if area <= 1_500_000:
        return 4
    if area <= 10_000_000:
        return 2
    return 1


def _rounded_mask(size: tuple[int, int], radius: int, scale: int) -> Image.Image:
    width, height = size
    if scale <= 1:
        mask = Image.new("L", (width, height), 0)
        ImageDraw.Draw(mask).rounded_rectangle(
            (0, 0, width - 1, height - 1), radius=radius, fill=255
        )
        return mask

    big = Image.new("L", (width * scale, height * scale), 0)
    ImageDraw.Draw(big).rounded_rectangle(
        (0, 0, width * scale - 1, height * scale - 1), radius=radius * scale, fill=255
    )
    return big.resize((width, height), Image.Resampling.LANCZOS)


def _rect_mask(
    size: tuple[int, int], rect: tuple[int, int, int, int], radius: int, scale: int
) -> Image.Image:
    width, height = size
    if scale <= 1:
        mask = Image.new("L", (width, height), 0)
        ImageDraw.Draw(mask).rounded_rectangle(rect, radius=radius, fill=255)
        return mask

    big = Image.new("L", (width * scale, height * scale), 0)
    ImageDraw.Draw(big).rounded_rectangle(
        tuple(value * scale for value in rect), radius=radius * scale, fill=255
    )
    return big.resize((width, height), Image.Resampling.LANCZOS)


def _shadow_mask(
    size: tuple[int, int],
    box: tuple[int, int, int, int],
    radius: int,
    extents: tuple[int, int, int, int],
    power: int,
    alpha: int,
    sharp: bool,
    scale: int,
) -> Image.Image:
    """Hyprland's shadow falloff as an L mask, drawn as nested rounded rectangles.

    Each rectangle is the window box grown by a fraction of `extents` (left, top, right,
    bottom), so filling them from the outside in leaves every pixel with the alpha of its own
    distance, which is exactly the shader's curve. `sharp` is the compositor's no-falloff
    mode: one flat rectangle.

    The four extents differ on purpose. Hyprland shifts the whole shadow box by
    `decoration:shadow:offset`, which leaves the offset's width at full alpha under the
    window and reads as a hard-edged block once the shadow is strong. Stretching the falloff
    instead keeps the shadow attached to the window and still drops it downwards.
    """
    x0, y0, x1, y1 = box
    width = x1 - x0 + 1
    height = y1 - y0 + 1
    spread = max(extents)
    mask = Image.new("L", (size[0] * scale, size[1] * scale), 0)
    draw = ImageDraw.Draw(mask)

    if sharp:
        left, top, right, bottom = extents
        draw.rounded_rectangle(
            (
                (x0 - left) * scale,
                (y0 - top) * scale,
                (x1 + right + 1) * scale - 1,
                (y1 + bottom + 1) * scale - 1,
            ),
            radius=radius * scale,
            fill=alpha,
        )
        return mask.resize(size, Image.Resampling.LANCZOS) if scale > 1 else mask

    for step in range(spread, -1, -1):
        fraction = step / spread
        value = round(alpha * (1 - fraction) ** power)
        if value <= 0:
            continue
        reach = [fraction * extent for extent in extents]
        corner = min(
            round(radius + fraction * spread),
            (width + round(reach[0] + reach[2])) // 2,
            (height + round(reach[1] + reach[3])) // 2,
        )
        # The +1 makes the supersampled rectangle end on the 1x pixel edge, not its centre.
        draw.rounded_rectangle(
            (
                round((x0 - reach[0]) * scale),
                round((y0 - reach[1]) * scale),
                round((x1 + reach[2] + 1) * scale) - 1,
                round((y1 + reach[3] + 1) * scale) - 1,
            ),
            radius=corner * scale,
            fill=value,
        )

    return mask.resize(size, Image.Resampling.LANCZOS) if scale > 1 else mask


def render(raw: bytes, style: WindowStyle | None = None) -> bytes:
    if style is None:
        style = WindowStyle()

    with Image.open(BytesIO(raw)) as opened:
        window = opened.convert("RGBA")

    width, height = window.size
    border = max(0, style.border_size)
    outer_width = width + border * 2
    outer_height = height + border * 2
    rounding = min(style.rounding, outer_width // 2, outer_height // 2)
    inner_rounding = max(0, rounding - border)

    extent = max(0, style.shadow_range)
    if not (style.shadow_enabled and style.shadow_color[3]):
        extent = 0

    offset_x, offset_y = style.shadow_offset
    # Hyprland grows the window box by `range` and then scales it about its own centre, so a
    # scale below 1 pulls the shadow's outer edge towards the window -- for a window larger
    # than the range it lands inside it, where the window hides the shadow completely.
    extents = (0, 0, 0, 0)
    alpha = 0
    if extent:
        reach_x = (outer_width / 2 + extent) * style.shadow_scale - outer_width / 2
        reach_y = (outer_height / 2 + extent) * style.shadow_scale - outer_height / 2
        extents = (
            max(0, round(reach_x) + max(0, -offset_x)),
            max(0, round(reach_y) + max(0, -offset_y)),
            max(0, round(reach_x) + max(0, offset_x)),
            max(0, round(reach_y) + max(0, offset_y)),
        )
        # The shader keeps the falloff's shape but starts it lower when the reach shrank.
        reaching = [reach for reach in (reach_x, reach_y) if reach > 0]
        alpha = (
            round(
                style.shadow_color[3] * (min(reaching) / extent) ** style.shadow_power
            )
            if reaching
            else 0
        )
    padding = max(extents)
    # Transparent, so the result can be dropped onto any background; the shadow lives in the
    # alpha channel and stays visible over whatever the viewer draws behind it.
    canvas = Image.new(
        "RGBA",
        (outer_width + padding * 2, outer_height + padding * 2),
        (0, 0, 0, 0),
    )

    if padding:
        box = (
            padding,
            padding,
            padding + outer_width - 1,
            padding + outer_height - 1,
        )
        mask = _shadow_mask(
            canvas.size,
            box,
            rounding,
            extents,
            style.shadow_power,
            alpha,
            style.shadow_sharp,
            _supersample(*canvas.size),
        )
        shadow = Image.new("RGBA", canvas.size, (*style.shadow_color[:3], 0))
        shadow.putalpha(mask)
        canvas.alpha_composite(shadow)

    # The border is painted outside the surface; the content keeps its full size and is
    # clipped by the inner radius, like a compositor border ring. Both masks are drawn
    # supersampled and reduced, because Pillow's rounded_rectangle has no antialiasing.
    content_mask = _rounded_mask(
        (width, height), inner_rounding, _supersample(width, height)
    )
    window.putalpha(ImageChops.multiply(window.getchannel("A"), content_mask))
    canvas.alpha_composite(window, (padding + border, padding + border))

    if border and style.border_color[3]:
        scale = _supersample(*canvas.size)
        outer_mask = _rect_mask(
            canvas.size,
            (padding, padding, padding + outer_width - 1, padding + outer_height - 1),
            rounding,
            scale,
        )
        inner_mask = _rect_mask(
            canvas.size,
            (
                padding + border,
                padding + border,
                padding + border + width - 1,
                padding + border + height - 1,
            ),
            inner_rounding,
            scale,
        )
        ring = ImageChops.subtract(outer_mask, inner_mask)
        border_layer = Image.new("RGBA", canvas.size, (*style.border_color[:3], 0))
        border_layer.putalpha(
            ring.point(lambda value: value * style.border_color[3] // 255)
        )
        canvas.alpha_composite(border_layer)

    result = BytesIO()
    canvas.save(result, "PNG")
    return result.getvalue()
