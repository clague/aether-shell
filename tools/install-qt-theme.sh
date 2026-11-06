#!/usr/bin/env bash
# Install Aether's Qt platform theme into the per-user Qt plugin directory.
#
#   ./tools/install-qt-theme.sh            # build/ -> ~/.local/lib/qt6/plugins
#   ./tools/install-qt-theme.sh --remove    # take it back out
#
# Why a script rather than `make install`: the theme has to be reachable by every Qt application
# on the session, including the ones the compositor starts, and those do not inherit this shell's
# environment. A system install puts it in <prefix>/lib/qt6/plugins/platformthemes, which Qt scans
# on its own; for a checkout, the per-user directory is the only path that needs no absolute
# source tree baked into the compositor config.
#
# It is a plugin, so it must be rebuilt after a Qt upgrade, exactly like quickshell: the private
# headers it is compiled against change with the Qt version.

set -euo pipefail

cd "$(git rev-parse --show-toplevel)"
BUILD_DIR=${BUILD_DIR:-$PWD/build}
DEST=${AETHER_QT_THEME_DIR:-${HOME}/.local/lib/qt6/plugins/platformthemes}
SRC="$BUILD_DIR/plugins/platformthemes/libaethertheme.so"

red() { printf '\033[1;31m%s\033[0m' "$*"; }
blue() { printf '\033[1;34m%s\033[0m' "$*"; }

case ${1:-} in
    -h|--help)
        sed -n '2,17p' "$0"
        exit 0
        ;;
    --remove)
        rm -f "$DEST/libaethertheme.so"
        printf '%s removed %s\n' "$(blue ==\>)" "$DEST/libaethertheme.so"
        printf '     drop QT_QPA_PLATFORMTHEME=aether from ~/.config/aether/hypr-user.lua\n'
        exit 0
        ;;
esac

if [ ! -f "$SRC" ]; then
    printf '%s %s missing\n' "$(red fail)" "$SRC"
    printf '     build it first:  cmake --build %s --target aether-qt-theme\n' "$BUILD_DIR"
    exit 2
fi

# The plugin directory is a normal install tree, so keep the platformthemes level that Qt expects.
mkdir -p "$DEST"
install -m 0755 "$SRC" "$DEST/libaethertheme.so"
printf '%s %s\n' "$(blue ==\>)" "$DEST/libaethertheme.so"
printf '     set QT_QPA_PLATFORMTHEME=aether and QT_PLUGIN_PATH=%s\n' "${DEST%/platformthemes}"
printf '     in ~/.config/aether/hypr-user.lua, not in the shared hypr config\n'
