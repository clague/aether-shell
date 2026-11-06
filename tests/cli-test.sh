#!/usr/bin/env bash
# Exercises the in-tree command surface against throwaway XDG directories.
#
# The scheme and wallpaper writers are the code that can ruin a desktop, and every other gate
# only greps or starts QML -- neither runs `aether`. Fan-out to real apps is disabled through
# cli.json so this test never touches ~/.config/{fuzzel,htop,cava,gtk}.
set -euo pipefail

ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
AETHER=$ROOT/bin/aether
WALL=$ROOT/assets/wallpapers/Gravitation.png

work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT

export XDG_CONFIG_HOME=$work/config
export XDG_STATE_HOME=$work/state
export XDG_CACHE_HOME=$work/cache
export XDG_DATA_HOME=$work/share
export XDG_RUNTIME_DIR=$work/run
mkdir -p "$XDG_CONFIG_HOME/aether" "$XDG_STATE_HOME" "$XDG_CACHE_HOME" "$XDG_DATA_HOME" "$XDG_RUNTIME_DIR"
chmod 700 "$XDG_RUNTIME_DIR"

cat >"$XDG_CONFIG_HOME/aether/cli.json" <<'JSON'
{
    "theme": {
        "enableTerm": false,
        "enableHypr": true,
        "enableDiscord": false,
        "enableSpicetify": false,
        "enablePandora": false,
        "enableFuzzel": true,
        "enableBtop": false,
        "enableNvtop": false,
        "enableHtop": false,
        "enableGtk": false,
        "enableWarp": false,
        "enableChromium": false,
        "enableZed": false,
        "enableCava": false
    }
}
JSON

checks=0
check() { # check <description> <expected> <actual>
    if [ "$2" != "$3" ]; then
        printf 'FAIL: %s\n  expected: %s\n  actual:   %s\n' "$1" "$2" "$3" >&2
        exit 1
    fi
    checks=$((checks + 1))
}

scheme_state=$XDG_STATE_HOME/aether/scheme.json

"$AETHER" scheme set -n catppuccin -f mocha
read -r name flavour mode < <(python3 -c \
    'import json,sys; d=json.load(open(sys.argv[1])); print(d["name"], d["flavour"], d["mode"])' "$scheme_state")
check "scheme name is written" catppuccin "$name"
check "scheme flavour is written" mocha "$flavour"
check "scheme mode is written" dark "$mode"

# The compositor file must be Lua even when Hyprland cannot be reached (this test has no
# socket): conf content in current.lua breaks the whole config at the next login.
check "hypr scheme is Lua" "return {" \
    "$(head -c 8 "$XDG_STATE_HOME/aether/scheme/current.lua")"

# A user-owned config is kept once before the first overwrite.
mkdir -p "$XDG_CONFIG_HOME/fuzzel"
printf 'font=MyFuzzel\n' >"$XDG_CONFIG_HOME/fuzzel/fuzzel.ini"
"$AETHER" scheme set -m dark
check "existing fuzzel config is backed up" "font=MyFuzzel" \
    "$(cat "$XDG_CONFIG_HOME/fuzzel/fuzzel.ini.aether.bak")"
check "fuzzel config is themed" "0" \
    "$(grep -c 'MyFuzzel' "$XDG_CONFIG_HOME/fuzzel/fuzzel.ini" || true)"

before=$(sha256sum "$scheme_state" | cut -d' ' -f1)
preview=$("$AETHER" scheme preview -v vibrant)
after=$(sha256sum "$scheme_state" | cut -d' ' -f1)
check "preview leaves scheme.json alone" "$before" "$after"
check "preview reports the requested variant" vibrant \
    "$(python3 -c 'import json,sys; print(json.load(sys.stdin)["variant"])' <<<"$preview")"

"$AETHER" scheme set -v vibrant
check "set applies the variant" vibrant "$("$AETHER" scheme get -v)"

if "$AETHER" wallpaper -f /nope >"$work/badwall.out" 2>&1; then
    echo "FAIL: an invalid wallpaper path was accepted" >&2
    exit 1
fi
grep -q "not a valid image or video" "$work/badwall.out"
if grep -q "Traceback" "$work/badwall.out"; then echo "FAIL: traceback for a bad wallpaper" >&2; exit 1; fi
checks=$((checks + 2))

if "$AETHER" scheme set -n dynamic >"$work/nodyn.out" 2>&1; then
    echo "FAIL: dynamic scheme accepted without a wallpaper" >&2
    exit 1
fi
grep -q "No wallpaper set" "$work/nodyn.out"
if grep -q "Traceback" "$work/nodyn.out"; then echo "FAIL: traceback for dynamic without wallpaper" >&2; exit 1; fi
checks=$((checks + 2))

"$AETHER" ipc --help | grep -q "usage: aether ipc"
checks=$((checks + 1))

"$AETHER" wallpaper -f "$WALL" -N
check "wallpaper path is written" "$WALL" "$(cat "$XDG_STATE_HOME/aether/wallpaper/path.txt")"
check "current symlink resolves to the file" "$WALL" "$(readlink -f "$XDG_STATE_HOME/aether/wallpaper/current")"
[ -s "$XDG_STATE_HOME/aether/wallpaper/thumbnail.jpg" ]
checks=$((checks + 1))

mkdir -p "$work/walls"
cp "$WALL" "$work/walls/only.png"
"$AETHER" wallpaper -r "$work/walls" -N
check "random wallpaper writes the path" "$work/walls/only.png" \
    "$(cat "$XDG_STATE_HOME/aether/wallpaper/path.txt")"

case "$("$AETHER" wallpaper -p "$WALL" -N)" in
    '{"name": "dynamic"'*) checks=$((checks + 1)) ;;
    *) echo "FAIL: wallpaper -p did not print a scheme" >&2; exit 1 ;;
esac

[ -n "$("$AETHER" --version)" ]
checks=$((checks + 1))

# Window capture: explicit stableId skips the Hyprland socket, and the fakes keep grim,
# swappy and wl-copy from touching the real desktop. The fake grim returns a tiny real PNG so
# the window renderer (padding, border, shadow) can be checked as an image, not a byte string.
mkdir -p "$work/bin"
python3 -c 'import sys; from PIL import Image; Image.new("RGBA", (20, 10), (180, 40, 40, 255)).save(sys.argv[1])' "$work/window.png"
cat >"$work/bin/grim" <<'EOF'
#!/bin/sh
printf '%s' "$*" >"$GRIM_ARGS"
cat "$FAKE_WINDOW"
EOF
cat >"$work/bin/swappy" <<'EOF'
#!/bin/sh
printf '%s' "$*" >"$SWAPPY_ARGS"
cat >"$SWAPPY_STDIN"
EOF
cat >"$work/bin/wl-copy" <<'EOF'
#!/bin/sh
cat >"$WL_COPY_OUT"
EOF
chmod +x "$work/bin/grim" "$work/bin/swappy" "$work/bin/wl-copy"

framed() {
    python3 -c 'import sys
from PIL import Image
im = Image.open(sys.argv[1])
assert im.mode == "RGBA", im.mode
assert im.size[0] > 20 and im.size[1] > 10, im.size
print("framed")' "$1"
}

GRIM_ARGS=$work/grim.args FAKE_WINDOW=$work/window.png SWAPPY_ARGS=$work/swappy.args \
    SWAPPY_STDIN=$work/swappy.stdin PATH="$work/bin:$PATH" "$AETHER" screenshot -w 180001e3
check "window capture uses grim -T" "-T 180001e3 -" "$(cat "$work/grim.args")"
check "window capture opens swappy on stdin" "-f -" "$(cat "$work/swappy.args")"
for _ in $(seq 1 20); do [ -s "$work/swappy.stdin" ] && break; sleep 0.05; done
check "window capture is rendered with padding" "framed" "$(framed "$work/swappy.stdin")"

GRIM_ARGS=$work/grim.args FAKE_WINDOW=$work/window.png WL_COPY_OUT=$work/wl-copy.out \
    PATH="$work/bin:$PATH" "$AETHER" screenshot -w 180001e3 --clipboard
check "window clipboard is rendered too" "framed" "$(framed "$work/wl-copy.out")"

cat >"$XDG_CONFIG_HOME/aether/shell.json" <<'JSON'
{"aether":{"windowFrame":{"followWm":false,"rounding":0,"borderSize":0,"shadowEnabled":false,"borderColor":"rgba(0, 0, 0, 0)","shadowColor":"rgba(0, 0, 0, 0)"}}}
JSON
GRIM_ARGS=$work/grim.args FAKE_WINDOW=$work/window.png SWAPPY_ARGS=$work/swappy.args \
    SWAPPY_STDIN=$work/swappy-custom.png PATH="$work/bin:$PATH" "$AETHER" screenshot -w 180001e3
for _ in $(seq 1 20); do [ -s "$work/swappy-custom.png" ] && break; sleep 0.05; done
custom_size=$(python3 -c 'import sys; from PIL import Image; im = Image.open(sys.argv[1]); print(f"{im.size[0]}x{im.size[1]}")' "$work/swappy-custom.png")
check "custom frame can disable the frame" "20x10" "$custom_size"

if "$AETHER" screenshot -w 1 -r >"$work/window-region.out" 2>&1; then
    echo "FAIL: --window and --region were accepted together" >&2
    exit 1
fi
grep -q "cannot be used together" "$work/window-region.out"
checks=$((checks + 1))

printf 'PASS: %d check(s)\n' "$checks"
