"""Render a captured window like a macOS window screenshot.

The frame follows the running Hyprland configuration: rounding, border size/colour and the
shadow range, power, offset and colour. When Hyprland cannot be queried (a test, a script
outside the session) the defaults below are used.
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
    radius = min(style.rounding, width // 2, height // 2)

    mask = Image.new("L", (width, height), 0)
    ImageDraw.Draw(mask).rounded_rectangle(
        (0, 0, width - 1, height - 1), radius=radius, fill=255
    )
    window.putalpha(ImageChops.multiply(window.getchannel("A"), mask))

    # Hyprland's render_power makes the shadow crisper as it rises; use it to shrink the blur
    # while keeping the configured range as the canvas extent.
    blur = (
        max(1, round(style.shadow_range * 2 / style.shadow_power))
        if style.shadow_range
        else 0
    )
    extent = max(style.shadow_range, blur)
    offset_x, offset_y = style.shadow_offset
    padding = extent + max(abs(offset_x), abs(offset_y)) + style.border_size
    canvas = Image.new(
        "RGBA", (width + padding * 2, height + padding * 2), (0, 0, 0, 0)
    )

    if style.shadow_range and style.shadow_color[3]:
        shadow = Image.new("RGBA", canvas.size, (0, 0, 0, 0))
        ImageDraw.Draw(shadow).rounded_rectangle(
            (
                padding + offset_x,
                padding + offset_y,
                padding + offset_x + width - 1,
                padding + offset_y + height - 1,
            ),
            radius=radius,
            fill=style.shadow_color,
        )
        canvas.alpha_composite(shadow.filter(ImageFilter.GaussianBlur(blur)))

    canvas.alpha_composite(window, (padding, padding))

    if style.border_size and style.border_color[3]:
        ImageDraw.Draw(canvas).rounded_rectangle(
            (padding, padding, padding + width - 1, padding + height - 1),
            radius=radius,
            outline=style.border_color,
            width=style.border_size,
        )

    result = BytesIO()
    canvas.save(result, "PNG")
    return result.getvalue()
