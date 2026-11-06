#!/usr/bin/env python3
"""Check the translation catalog against the strings the QML actually uses.

    i18n-check.py            missing and unused entries
    i18n-check.py --self-test  prove the check catches both

A `Tr.tr("...")` whose msgid is absent from the catalog renders as English in a Chinese UI, and
nothing else notices: qmllint does not know about the catalog, and a stale entry is invisible
until someone greps for it. Dynamic calls (`Tr.tr(someVariable)`) cannot be checked this way and
are counted separately rather than reported as missing.
"""

import re
import sys
import tempfile
from collections import Counter
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
CATALOG = ROOT / "plugin/src/Aether/I18n/trs/zh_CN.po"
SOURCES = ["modules", "components", "services", "daemons", "utils"]

TR = re.compile(r'Tr\.tr\("((?:[^"\\]|\\.)*)"\)')
TRCTX = re.compile(r'Tr\.trCtx\("((?:[^"\\]|\\.)*)",\s*"((?:[^"\\]|\\.)*)"\)')
DYNAMIC = re.compile(r'Tr\.tr\((?!")')


def field(block: str, name: str) -> str | None:
    """One PO field, with its continuation lines joined (a long string spans several)."""
    match = re.search(rf'^{name} "((?:[^"\\\\]|\\\\.)*)"$', block, re.M)
    if not match:
        return None

    value = match.group(1)
    for line in block[match.end() :].splitlines():
        line = line.strip()
        if not line.startswith('"'):
            break
        value += line[1:-1]
    return value


def po_entries(text: str) -> dict[tuple[str, str], str]:
    """(msgctxt, msgid) -> msgstr.

    Line by line rather than block by block: entries in this catalog are not always separated by
    a blank line, and a long string continues on following lines, so both would be misread by a
    split on empty lines.
    """
    entries: dict[tuple[str, str], str] = {}
    ctx, msgid, msgstr = "", None, None
    target = None  # which of msgid/msgstr the next continuation line belongs to

    def flush():
        nonlocal ctx, msgid, msgstr
        if msgid:
            entries[(ctx, msgid)] = msgstr or ""
        ctx, msgid, msgstr, target = "", None, None, None

    for raw in text.splitlines():
        line = raw.strip()
        if not line:
            continue
        if line.startswith("#"):
            if msgid and msgstr is not None:
                flush()
            continue
        if line.startswith("msgctxt "):
            if msgid:
                flush()
            ctx = field_of(line)
            target = None
        elif line.startswith("msgid "):
            if msgid:
                flush()
            msgid = field_of(line)
            target = "msgid"
        elif line.startswith("msgstr "):
            msgstr = field_of(line)
            target = "msgstr"
        elif line.startswith('"') and target:
            value = line[1:-1]
            if target == "msgid":
                msgid += value
            else:
                msgstr += value
    flush()
    return entries


def field_of(line: str) -> str:
    """The quoted part of `msgid "..."`, without its delimiters."""
    start = line.index('"')
    return line[start + 1 : -1]


def used_strings(roots) -> tuple[Counter, Counter, int]:
    plain, contextual, dynamic = Counter(), Counter(), 0
    for root in roots:
        for path in root.rglob("*.qml"):
            source = path.read_text()
            plain.update(TR.findall(source))
            contextual.update(TRCTX.findall(source))
            dynamic += len(DYNAMIC.findall(source))
    return plain, contextual, dynamic


# Proper nouns and units that are meant to stay in English. Everything else whose translation is
# identical to the source is a string someone forgot to translate, which "missing" cannot see.
KEPT_IN_ENGLISH = {
    "CLI", "CPU", "Discord Rich Presence", "Dwindle", "Emoji", "Enter", "Esc", "GPU", "GitHub",
    "Hyprland", "IPv4", "IPv6", "K", "Logo", "Master", "NetworkManager", "Nexus — %1",
    "OpenClaw", "OpenRouter", "PIN", "REC", "Scrolling", "Shell", "Spotify", "VPN", "WS",
    "Wallhaven", "Wallpaper Engine", "Wi-Fi", "%1 Hz", "%1 MHz", "%1 Gbps", "%1 Mbps",
    "%1 km/h", "2.4 GHz", "5 GHz", "null",
}


def untranslated(entries: dict[tuple[str, str], str]) -> list[str]:
    """Entries whose translation is exactly the source, minus the ones meant to stay English."""
    out = []
    for (_, msgid), msgstr in entries.items():
        if not msgid or msgstr != msgid or msgid in KEPT_IN_ENGLISH:
            continue
        # Only real words: a capitalised string containing a run of lowercase letters. Units
        # ("%1 TiB/s", "%1 ms"), symbols and shell commands are not translatable text.
        if msgid[0].isupper() and re.search(r"[a-z]{3,}", msgid):
            out.append(msgid)
    return sorted(out)


def check(roots, catalog: Path) -> tuple[list, list, int]:
    plain, contextual, dynamic = used_strings(roots)
    entries = po_entries(catalog.read_text())

    missing = [
        (msgid, "") for msgid, count in plain.items() if not entries.get(("", msgid))
    ] + [
        (msgid, context)
        for msgid, context in contextual
        if not entries.get((context, msgid))
    ]

    used_keys = {("", msgid) for msgid in plain} | {(context, msgid) for msgid, context in contextual}
    unused = [key for key in entries if key not in used_keys]
    return missing, unused, dynamic


FIXTURE_PO = """\
msgid ""
msgstr "Content-Type: text/plain; charset=UTF-8"

#: a.qml
msgid "Translated"
msgstr "已翻译"

#: a.qml
msgid "Stale"
msgstr "过期"

#: b.qml
msgctxt "verb"
msgid "Close"
msgstr "关闭"

#: b.qml
msgid "Bluetooth"
msgstr "Bluetooth"

#: b.qml
msgid "%1 ms"
msgstr "%1 ms"
"""

FIXTURE_QML = """\
Item {
    Component.onCompleted: {
        Tr.tr("Translated");
        Tr.tr("Untranslated");
        Tr.trCtx("Close", "verb");
        Tr.trCtx("Close", "adjective");
        Tr.tr(dynamicTitle);
    }
}
"""


def self_test() -> int:
    with tempfile.TemporaryDirectory() as tmp:
        root = Path(tmp)
        (root / "a.qml").write_text(FIXTURE_QML)
        catalog = root / "zh_CN.po"
        catalog.write_text(FIXTURE_PO)

        missing, unused, dynamic = check([root], catalog)
        missing_ids = sorted(m[0] for m in missing)
        assert missing_ids == ["Close", "Untranslated"], missing_ids
        assert "Stale" in [u[1] for u in unused], unused
        assert dynamic == 1, dynamic
        assert untranslated(po_entries(FIXTURE_PO)) == ["Bluetooth"], "untranslated"

    print(
        "PASS self-test: finds the untranslated string, the wrong context and the stale entry"
    )
    return 0


def main() -> int:
    if "--self-test" in sys.argv:
        return self_test()

    roots = [ROOT / name for name in SOURCES if (ROOT / name).is_dir()]
    missing, unused, dynamic = check(roots, CATALOG)

    for msgid, context in sorted(missing):
        where = f' (context "{context}")' if context else ""
        print(f"missing  {msgid!r}{where}")
    if "--unused" in sys.argv:
        for context, msgid in sorted(unused):
            where = f' (context "{context}")' if context else ""
            print(f"unused   {msgid!r}{where}")

    english = untranslated(po_entries(CATALOG.read_text()))
    for msgid in english:
        print(f"english  {msgid!r}")

    print(
        f"{len(missing)} missing, {len(english)} untranslated, {len(unused)} unused, "
        f"{dynamic} dynamic call(s) not checked"
    )
    return 1 if missing or english else 0


if __name__ == "__main__":
    sys.exit(main())
