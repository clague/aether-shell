#!/bin/sh
# Askpass helper: show the shell's password dialog and print what was typed.
#
# Point SSH_ASKPASS and SUDO_ASKPASS at this file; see hybrid/docs/askpass.md.
set -eu

prompt="${1:-Password}"
qs="${QS:-qs}"

id=$("$qs" -c caelestia ipc call askpass request "$prompt") || exit 1
[ -n "$id" ] || exit 1

# The dialog stays up until it is answered or cancelled. A helper that is killed leaves the
# request to the shell's own timeout rather than tidying up here.
while :; do
    answer=$("$qs" -c caelestia ipc call askpass poll "$id") || exit 1
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
