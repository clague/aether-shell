#!/bin/sh
# Askpass helper: show the shell's password dialog and print what was typed.
#
# Point SSH_ASKPASS and SUDO_ASKPASS at this file; see docs/askpass.md.
set -eu

prompt="${1:-Password}"
qs="${QS:-qs}"

# The shell is found by path, not by name: `qs -c caelestia` resolves whichever config the user
# has installed, which may be a different tree than this script. readlink resolves the symlink
# the docs suggest putting in ~/.local/bin.
root=$(CDPATH= cd -- "$(dirname -- "$(readlink -f -- "$0")")/.." && pwd)

id=$("$qs" -p "$root" ipc call askpass request "$prompt") || exit 1
[ -n "$id" ] || exit 1

# The dialog stays up until it is answered or cancelled. A helper that is killed leaves the
# request to the shell's own timeout rather than tidying up here.
while :; do
    answer=$("$qs" -p "$root" ipc call askpass poll "$id") || exit 1
    case "$answer" in
        pending) sleep 0.15 ;;
        ok:*)
            printf '%s\n' "${answer#ok:}"
            exit 0
            ;;
        *)
            # "cancel", "unknown", or a shell that went away
            exit 1
            ;;
    esac
done
