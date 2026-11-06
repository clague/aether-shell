#!/usr/bin/env sh

cat ~/.local/state/aether/sequences.txt 2>/dev/null

exec "$@"
