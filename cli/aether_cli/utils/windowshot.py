"""Render a captured window like a macOS window screenshot.

Hyprland exposes no API that renders a window *with its server-side decorations* to an alpha
buffer: toplevel export explicitly excludes them, while workspace/output capture includes the
desktop background. The frame is therefore reconstructed from the values Hyprland does expose.

The values come from the running compositor: rounding, border size/colour, and shadow
enabled/sharp/range/power/offset/colour. Each field falls back independently when hyprctl is
unavailable (tests, scripts outside the session).
"""

import json
import subprocess
from dataclasses import dataclass
from io import BytesIO

from PIL import Image, ImageChops, ImageDraw, ImageFilter


@dataclass(frozen=True)
class WindowStyle:
    rounding: int = 12
    border_size: int = 1
    border_color: tuple[int, int, int, int] = (0, 0, 0, 55)
    shadow_enabled: bool = True
    shadow_sharp: bool = False
    shadow_range: int = 24
    shadow_power: int = 4
    shadow_offset: tuple[int, int] = (0, 10)
    shadow_color: tuple[int, int, int, int] = (0, 0, 0, 90)


def _clamp(value: int) -> int:
    return max(0, min(255, value))


def parse_color(
    value: str | None, fallback: tuple[int, int, int, int]
) -> tuple[int, int, int, int]:
    """Hyprland colours are AARRGGBB hex, or rgba(...) with hex or comma-separated channels."""
    if not value:
        return fallback

    token = str(value).strip().split()[0].lower()
    if token.startswith("rgba(") and token.endswith(")"):
        inner = token[5:-1]
        if "," in inner:
            parts = [float(part) for part in inner.split(",")]
            if len(parts) == 4:
                rgb = [
                    round(part * 255) if part <= 1 else round(part)
                    for part in parts[:3]
                ]
                alpha = round(parts[3] * 255) if parts[3] <= 1 else round(parts[3])
                return _clamp(rgb[0]), _clamp(rgb[1]), _clamp(rgb[2]), _clamp(alpha)
        elif len(inner) == 8:
            token = inner
    elif token.startswith("rgb(") and token.endswith(")"):
        parts = [float(part) for part in token[4:-1].split(",")]
        if len(parts) == 3:
            rgb = [round(part * 255) if part <= 1 else round(part) for part in parts]
            return _clamp(rgb[0]), _clamp(rgb[1]), _clamp(rgb[2]), 255

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
        shadow_offset=_offset("decoration:shadow:offset", (0, 10)),
        shadow_color=_color("decoration:shadow:color", (0, 0, 0, 90)),
    )


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

    blur = 0
    extent = 0
    if style.shadow_enabled and style.shadow_range and style.shadow_color[3]:
        # Hyprland's render_power makes the shadow crisper as it rises; the range is the
        # configured extent. A Gaussian blur approximates the falloff, not the exact curve.
        blur = (
            0
            if style.shadow_sharp
            else max(1, round(style.shadow_range * 2 / style.shadow_power))
        )
        extent = max(style.shadow_range, blur)

    offset_x, offset_y = style.shadow_offset
    padding = extent + max(abs(offset_x), abs(offset_y)) if extent else 0
    canvas = Image.new(
        "RGBA",
        (outer_width + padding * 2, outer_height + padding * 2),
        (0, 0, 0, 0),
    )

    if extent:
        shadow = Image.new("RGBA", canvas.size, (0, 0, 0, 0))
        ImageDraw.Draw(shadow).rounded_rectangle(
            (
                padding + offset_x,
                padding + offset_y,
                padding + offset_x + outer_width - 1,
                padding + offset_y + outer_height - 1,
            ),
            radius=rounding,
            fill=style.shadow_color,
        )
        if blur:
            shadow = shadow.filter(ImageFilter.GaussianBlur(blur))
        canvas.alpha_composite(shadow)

    # The border is painted outside the surface; the content keeps its full size and is
    # clipped by the inner radius, like a compositor border ring.
    mask = Image.new("L", (width, height), 0)
    ImageDraw.Draw(mask).rounded_rectangle(
        (0, 0, width - 1, height - 1), radius=inner_rounding, fill=255
    )
    window.putalpha(ImageChops.multiply(window.getchannel("A"), mask))
    canvas.alpha_composite(window, (padding + border, padding + border))

    if border and style.border_color[3]:
        outer_mask = Image.new("L", canvas.size, 0)
        ImageDraw.Draw(outer_mask).rounded_rectangle(
            (padding, padding, padding + outer_width - 1, padding + outer_height - 1),
            radius=rounding,
            fill=255,
        )
        inner_mask = Image.new("L", canvas.size, 0)
        ImageDraw.Draw(inner_mask).rounded_rectangle(
            (
                padding + border,
                padding + border,
                padding + border + width - 1,
                padding + border + height - 1,
            ),
            radius=inner_rounding,
            fill=255,
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
