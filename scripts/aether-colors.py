#!/usr/bin/env python3
"""Write Aether's colour scheme in the KDE format, next to scheme.json.

    aether-colors.py [scheme.json] [-o aether.colors]

KDE applications do not paint from QPalette: Dolphin's places panel asks KColorScheme, which
reads a .colors file named by the KDE_COLOR_SCHEME_PATH application property. The Qt platform
theme sets that property and reads this file; it does not write it, because the file belongs to
the scheme, and the scheme is written when the shell applies it.

Called from services/Colours.qml whenever scheme.json changes, so the file is always a copy of
the scheme that is actually displayed. The same section layout and token mapping the Qt theme
uses for the palette, so both stay in step.
"""

import json
import os
import sys
import tempfile
from pathlib import Path

STATE = Path(os.getenv("XDG_STATE_HOME", Path.home() / ".local/state")) / "aether"


def colour(colours: dict, key: str, fallback: str = "") -> str:
    value = colours.get(key) or (colours.get(fallback) if fallback else "") or "000000"
    return "#" + value.lstrip("#")


def foregrounds(colours, normal, active=None, link="klink", visited="kvisited"):
    return {
        "ForegroundActive": colour(colours, active or normal, normal),
        "ForegroundInactive": colour(colours, "outline", "onSurfaceVariant"),
        "ForegroundLink": colour(colours, link, "primary"),
        "ForegroundNegative": colour(colours, "knegative", "error"),
        "ForegroundNeutral": colour(colours, "kneutral", "tertiary"),
        "ForegroundNormal": colour(colours, normal, "onSurface"),
        "ForegroundPositive": colour(colours, "kpositive", "success"),
        "ForegroundVisited": colour(colours, visited, "kvisited"),
    }


def scheme(colours: dict, name: str) -> str:
    sections = {
        "ColorEffects:Disabled": {
            "Color": colour(colours, "surfaceContainer"),
            "ColorAmount": "0.5",
            "ColorEffect": "3",
            "ContrastAmount": "0",
            "ContrastEffect": "0",
            "IntensityAmount": "0",
            "IntensityEffect": "0",
        },
        "ColorEffects:Inactive": {
            "ChangeSelectionColor": "true",
            "Color": colour(colours, "surfaceContainerLowest"),
            "ColorAmount": "0.025",
            "ColorEffect": "0",
            "ContrastAmount": "0.1",
            "ContrastEffect": "0",
            "Enable": "true",
            "IntensityAmount": "0",
            "IntensityEffect": "0",
        },
        "Colors:Button": {
            "BackgroundAlternate": colour(colours, "surfaceVariant"),
            "BackgroundNormal": colour(colours, "surfaceContainerHigh"),
            "DecorationFocus": colour(colours, "primary"),
            "DecorationHover": colour(colours, "primary"),
            **foregrounds(colours, "onSurface"),
        },
        "Colors:Complementary": {
            "BackgroundAlternate": colour(colours, "surface"),
            "BackgroundNormal": colour(colours, "surfaceContainer"),
            "DecorationFocus": colour(colours, "primary"),
            "DecorationHover": colour(colours, "primary"),
            **foregrounds(colours, "onSurfaceVariant", "inverseSurface"),
        },
        "Colors:Header": {
            "BackgroundAlternate": colour(colours, "surfaceContainer"),
            "BackgroundNormal": colour(colours, "surfaceContainer"),
            "DecorationFocus": colour(colours, "primary"),
            "DecorationHover": colour(colours, "primary"),
            **foregrounds(colours, "onSurfaceVariant", "inverseSurface"),
        },
        "Colors:Header][Inactive": {
            "BackgroundAlternate": colour(colours, "surfaceContainer"),
            "BackgroundNormal": colour(colours, "surfaceContainer"),
            "DecorationFocus": colour(colours, "primary"),
            "DecorationHover": colour(colours, "primary"),
            **foregrounds(colours, "onSurfaceVariant", "inverseSurface"),
        },
        "Colors:Selection": {
            "BackgroundAlternate": colour(colours, "primary"),
            "BackgroundNormal": colour(colours, "primary"),
            "DecorationFocus": colour(colours, "primary"),
            "DecorationHover": colour(colours, "secondary"),
            **foregrounds(
                colours, "onPrimary", "onPrimary", "klinkSelection", "kvisitedSelection"
            ),
        },
        "Colors:Tooltip": {
            "BackgroundAlternate": colour(colours, "surfaceVariant"),
            "BackgroundNormal": colour(colours, "surfaceContainer"),
            "DecorationFocus": colour(colours, "primary"),
            "DecorationHover": colour(colours, "primary"),
            **foregrounds(colours, "onSurface"),
        },
        "Colors:View": {
            "BackgroundAlternate": colour(colours, "surfaceContainer"),
            "BackgroundNormal": colour(colours, "surfaceDim"),
            "DecorationFocus": colour(colours, "primary"),
            "DecorationHover": colour(colours, "inversePrimary"),
            **foregrounds(colours, "onSurface", "inverseSurface"),
        },
        "Colors:Window": {
            "BackgroundAlternate": colour(colours, "surfaceVariant"),
            "BackgroundNormal": colour(colours, "surfaceContainer"),
            "DecorationFocus": colour(colours, "primary"),
            "DecorationHover": colour(colours, "primary"),
            **foregrounds(colours, "onSurfaceVariant", "klink"),
        },
        "General": {"ColorScheme": name, "Name": name, "shadeSortColumn": "true"},
        "KDE": {"contrast": "4"},
        "WM": {
            "activeBackground": colour(colours, "surfaceContainerHighest"),
            "activeBlend": "252,252,252",
            "activeForeground": colour(colours, "onSurface"),
            "inactiveBackground": colour(colours, "secondaryContainer"),
            "inactiveBlend": "161,169,177",
            "inactiveForeground": colour(colours, "onSecondaryContainer"),
        },
    }

    lines = []
    for name_, values in sections.items():
        lines.append("")
        lines.append(f"[{name_}]")
        lines.extend(f"{key}={value}" for key, value in values.items())
    return "\n".join(lines) + "\n"


def main() -> int:
    args = sys.argv[1:]
    source = (
        Path(args[0]) if args and not args[0].startswith("-") else STATE / "scheme.json"
    )
    target = STATE / "aether.colors"
    if "-o" in args:
        target = Path(args[args.index("-o") + 1])

    try:
        parsed = json.loads(source.read_text())
        colours = parsed["colours"]
        name = parsed.get("name") or "Aether"
    except (OSError, ValueError, KeyError) as error:
        print(f"aether-colors: cannot read {source}: {error}", file=sys.stderr)
        return 1

    body = scheme(colours, name)
    # Every shell start runs this, so only touch the file when the bytes actually changed:
    # rewriting it would wake every KColorScheme watcher on the desktop.
    if target.exists() and target.read_text() == body:
        return 0

    target.parent.mkdir(parents=True, exist_ok=True)
    with tempfile.NamedTemporaryFile("w", dir=target.parent, delete=False) as handle:
        handle.write(body)
        temp = Path(handle.name)
    temp.replace(target)
    return 0


if __name__ == "__main__":
    sys.exit(main())
