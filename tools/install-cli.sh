#!/usr/bin/env sh
# Put the in-tree command surface on PATH.
#
# QML calls it by absolute path, but Hyprland keybinds and execs.lua can only use a name, so
# `aether` has to resolve. This is a symlink, not a copy: the checkout stays the only source.
set -eu

root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
bin_dir="${XDG_BIN_HOME:-$HOME/.local/bin}"

mkdir -p "$bin_dir"
ln -sf "$root/bin/aether" "$bin_dir/aether"
# Same name a package install provides, so SSH_ASKPASS=aether-askpass works in both.
ln -sf "$root/scripts/askpass.sh" "$bin_dir/aether-askpass"

printf 'linked %s -> %s\n' "$bin_dir/aether" "$root/bin/aether"
printf 'linked %s -> %s\n' "$bin_dir/aether-askpass" "$root/scripts/askpass.sh"
case ":${PATH}:" in
    *":$bin_dir:"*) ;;
    *) printf 'warning: %s is not on PATH; add it or the Hyprland keybinds cannot find it\n' "$bin_dir" ;;
esac
