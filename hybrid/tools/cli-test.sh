#!/usr/bin/env bash
# Exercises the in-tree command surface against throwaway XDG directories.
#
# The scheme and wallpaper writers are the code that can ruin a desktop, and every other gate
# only greps or starts QML -- neither runs `aether`. Fan-out to real apps is disabled through
# cli.json so this test never touches ~/.config/{fuzzel,htop,cava,gtk}.
set -euo pipefail

ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)
AETHER=$ROOT/hybrid/bin/aether
WALL=$ROOT/assets/wallpapers/Gravitation.png

work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT

export XDG_CONFIG_HOME=$work/config
export XDG_STATE_HOME=$work/state
export XDG_CACHE_HOME=$work/cache
export XDG_DATA_HOME=$work/share
export XDG_RUNTIME_DIR=$work/run
mkdir -p "$XDG_CONFIG_HOME/caelestia" "$XDG_STATE_HOME" "$XDG_CACHE_HOME" "$XDG_DATA_HOME" "$XDG_RUNTIME_DIR"
chmod 700 "$XDG_RUNTIME_DIR"

cat >"$XDG_CONFIG_HOME/caelestia/cli.json" <<'JSON'
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

scheme_state=$XDG_STATE_HOME/caelestia/scheme.json

"$AETHER" scheme set -n catppuccin -f mocha
read -r name flavour mode < <(python3 -c \
    'import json,sys; d=json.load(open(sys.argv[1])); print(d["name"], d["flavour"], d["mode"])' "$scheme_state")
check "scheme name is written" catppuccin "$name"
check "scheme flavour is written" mocha "$flavour"
check "scheme mode is written" dark "$mode"

# The compositor file must be Lua even when Hyprland cannot be reached (this test has no
# socket): conf content in current.lua breaks the whole config at the next login.
check "hypr scheme is Lua" "return {" \
    "$(head -c 8 "$XDG_STATE_HOME/caelestia/scheme/current.lua")"

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
check "wallpaper path is written" "$WALL" "$(cat "$XDG_STATE_HOME/caelestia/wallpaper/path.txt")"
check "current symlink resolves to the file" "$WALL" "$(readlink -f "$XDG_STATE_HOME/caelestia/wallpaper/current")"
[ -s "$XDG_STATE_HOME/caelestia/wallpaper/thumbnail.jpg" ]
checks=$((checks + 1))

mkdir -p "$work/walls"
cp "$WALL" "$work/walls/only.png"
"$AETHER" wallpaper -r "$work/walls" -N
check "random wallpaper writes the path" "$work/walls/only.png" \
    "$(cat "$XDG_STATE_HOME/caelestia/wallpaper/path.txt")"

case "$("$AETHER" wallpaper -p "$WALL" -N)" in
    '{"name": "dynamic"'*) checks=$((checks + 1)) ;;
    *) echo "FAIL: wallpaper -p did not print a scheme" >&2; exit 1 ;;
esac

[ -n "$("$AETHER" --version)" ]
checks=$((checks + 1))

printf 'PASS: %d check(s)\n' "$checks"
