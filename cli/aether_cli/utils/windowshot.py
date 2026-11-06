"""Render a captured window like a macOS window screenshot.

The raw toplevel surface keeps its own alpha; this adds the presentation layer around it:
transparent padding, rounded corners, a one-pixel border and a soft drop shadow.
"""

from io import BytesIO

from PIL import Image, ImageChops, ImageDraw, ImageFilter

PADDING = 32
RADIUS = 12
SHADOW_OFFSET = 10
SHADOW_BLUR = 24
SHADOW_ALPHA = 90
BORDER_ALPHA = 55


def render(raw: bytes) -> bytes:
    with Image.open(BytesIO(raw)) as opened:
        window = opened.convert("RGBA")

    width, height = window.size
    radius = min(RADIUS, width // 2, height // 2)

    mask = Image.new("L", (width, height), 0)
    ImageDraw.Draw(mask).rounded_rectangle(
        (0, 0, width - 1, height - 1), radius=radius, fill=255
    )
    window.putalpha(ImageChops.multiply(window.getchannel("A"), mask))

    canvas = Image.new(
        "RGBA",
        (width + PADDING * 2, height + PADDING * 2 + SHADOW_OFFSET),
        (0, 0, 0, 0),
    )

    shadow = Image.new("RGBA", canvas.size, (0, 0, 0, 0))
    ImageDraw.Draw(shadow).rounded_rectangle(
        (
            PADDING,
            PADDING + SHADOW_OFFSET,
            PADDING + width - 1,
            PADDING + height - 1 + SHADOW_OFFSET,
        ),
        radius=radius,
        fill=(0, 0, 0, SHADOW_ALPHA),
    )
    canvas.alpha_composite(shadow.filter(ImageFilter.GaussianBlur(SHADOW_BLUR)))
    canvas.alpha_composite(window, (PADDING, PADDING))

    ImageDraw.Draw(canvas).rounded_rectangle(
        (PADDING, PADDING, PADDING + width - 1, PADDING + height - 1),
        radius=radius,
        outline=(0, 0, 0, BORDER_ALPHA),
        width=1,
    )

    result = BytesIO()
    canvas.save(result, "PNG")
    return result.getvalue()
