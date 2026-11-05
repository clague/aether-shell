#!/usr/bin/env python3
"""Fail when the tree calls the external caelestia CLI again.

The shell now ships its own command surface at `hybrid/bin/aether`. A stray `["caelestia", ...]`
compiles, lints and works on a machine that has caelestia-cli installed, so nothing else notices
that the checkout has grown a dependency it no longer declares.

caelestia:launcher and friends are IPC target names, not commands; ~/.config/caelestia and
caelestia-dots are paths; only an argv element or an executed command counts.
"""

import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]

SCAN_SUFFIXES = {".qml", ".lua", ".sh", ".py", ".json", ".conf", ".toml", ".hpp", ".cpp"}
# Docs quote the old CLI on purpose; generated and vendored trees are not call sites.
SKIP_DIRS = {".git", "build", ".verify", "hybrid/cli/aether_cli/data"}
SKIP_FILES = {"hybrid/tools/cli-deps.py"}

PATTERNS = [
    re.compile(r'\[\s*"caelestia"\s*,?'),  # QML/JSON argv
    re.compile(
        r"(?<![\w/.-])caelestia\s+(?:shell|scheme|screenshot|record|clipboard|emoji|wallpaper)\b"
    ),
    re.compile(r"site-packages/caelestia"),
]

# A line that also says aether has already been converted; keep the check honest by reporting it.
ALLOW = re.compile(
    r"caelestia:[\w-]+|caelestia[-/.]|\.config/caelestia|\.cache/caelestia|\.local/(?:state|share)/caelestia"
)

CASES = [
    ('Quickshell.execDetached(["caelestia", "scheme", "set"])', True),
    ('hl.exec_cmd("caelestia record")', True),
    ("cat /usr/lib/python3.14/site-packages/caelestia/data/emojis.txt", True),
    ("exec pkill fuzzel || caelestia clipboard", True),
    ('hl.dsp.global("caelestia:launcher")', False),
    ("~/.config/caelestia/scheme.json", False),
    ("install caelestia-dots/cli", False),
    ("the caelestia CLI writes it", False),
    ('config_dir / "caelestia/cli.json"', False),
    ('Quickshell.shellPath("hybrid/bin/aether")', False),
]


def flagged(line: str) -> bool:
    return any(p.search(line) for p in PATTERNS)


def self_test() -> int:
    bad = 0
    for line, expected in CASES:
        got = flagged(line)
        if got != expected:
            print(f"  FAIL: {line!r} -> {got}, wanted {expected}")
            bad += 1
    print(
        "PASS self-test: flags argv and exec calls, clears IPC names, paths and prose"
        if not bad
        else "FAIL"
    )
    return 1 if bad else 0


def scan() -> int:
    hits = []
    for path in sorted(ROOT.rglob("*")):
        if path.suffix not in SCAN_SUFFIXES or not path.is_file():
            continue
        rel = path.relative_to(ROOT)
        if str(rel) in SKIP_FILES or any(str(rel) == d or str(rel).startswith(d + "/") for d in SKIP_DIRS):
            continue
        try:
            lines = path.read_text(errors="replace").splitlines()
        except OSError:
            continue
        for number, line in enumerate(lines, 1):
            if flagged(line) and not ALLOW.search(line):
                hits.append(f"{rel}:{number}: {line.strip()}")

    for hit in hits:
        print(hit)
    print(f"{len(hits)} external CLI call(s)" if hits else "0 external CLI calls")
    return 1 if hits else 0


if __name__ == "__main__":
    if "--self-test" in sys.argv:
        sys.exit(self_test())
    sys.exit(scan())
