#!/usr/bin/env python3
"""Check that every `openSubPage(n)` opens the page its row advertises.

    subpage-index.py             report mismatches
    subpage-index.py --self-test build a broken tree and prove the check catches it

Each top-level Nexus page owns a StackPage in PageCompRegistry, and the n-th Component inside it
is sub-page n. A row that says "Clock" but pushes the index of something else is a navigation
bug no other gate can see: the QML compiles, qmllint is quiet, and the page opens -- just the
wrong one. Nine rows in the taskbar panel were off by three when this was written.
"""

import re
import sys
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
NEXUS = ROOT / "modules" / "nexus"

ROW_START = re.compile(r"\b(NavRow|RowButton|ButtonRow|IconTextButton)\s*\{")
# `subtext:` contains `text:`; the row's own label is the one not preceded by "sub".
TEXT = re.compile(r'(?<!sub)text:\s*Tr\.tr\("([^"]+)"\)')
SUBPAGE = re.compile(r"openSubPage\((\d+)\)")
TITLE = re.compile(r'title:\s*Tr\.tr\("([^"]+)"\)')
COMPONENT = re.compile(r"\n\s+([A-Z][A-Za-z0-9]*)\s*\{\}")
STACK = re.compile(r"StackPage\s*\{")

# Rows whose label deliberately differs from the page they open, because the label describes the
# action and the page describes the result. Everything else has to match.
KNOWN = {
    (
        "pages/NetworkPage.qml",
        "Add provider",
    ),  # opens the form that adds a VPN provider
    (
        "pages/WallpaperAndStyle.qml",
        "Wallpapers",
    ),  # the tab that reopens the wallpaper picker
    (
        "pages/wallandstyle/WallpaperSelect.qml",
        "Random",
    ),  # a category chip, opens that category's page
}


def body_at(text, open_brace):
    """The text between a `{` and its matching `}`."""
    depth = 0
    for i in range(open_brace, len(text)):
        if text[i] == "{":
            depth += 1
        elif text[i] == "}":
            depth -= 1
            if depth == 0:
                return text[open_brace + 1 : i]
    return ""


def row_blocks(text):
    """(label, sub-page index) for every row that opens a sub-page.

    A page can nest rows inside a container row, so each call is attributed to the innermost
    block that encloses it and to the label nearest above it -- otherwise a toolbar button that
    happens to sit before an unrelated row lends that row its text.
    """
    openers = [match.end() - 1 for match in ROW_START.finditer(text)]
    for call in SUBPAGE.finditer(text):
        enclosing = [start for start in openers if start < call.start()]
        if not enclosing:
            continue
        start = max(enclosing)
        labels = list(TEXT.finditer(body_at(text, start)[: call.start() - start]))
        if not labels:
            continue
        # A call inside a non-row container (a provider list delegate, say) would otherwise be
        # blamed on the last row that happened to open before it. Rows are short; anything
        # further away than this is not the row's own handler.
        label = labels[-1]
        if (
            text.count("\n", 0, call.start())
            - text.count("\n", 0, start + label.start())
            > 20
        ):
            continue
        yield label.group(1), int(call.group(1))


def stacks(registry):
    """Component class names per StackPage, in registry order."""
    return [
        COMPONENT.findall(body_at(registry, match.end() - 1))
        for match in STACK.finditer(registry)
    ]


def page_titles(pages_dir):
    titles = {}
    for path in pages_dir.rglob("*.qml"):
        title = TITLE.search(path.read_text())
        if title:
            titles[path.stem] = title.group(1)
    return titles


def normalise(text):
    return re.sub(r"[^a-z0-9]+", "", text.lower())


def scan(nexus):
    """[(file, label, index, target title)] for rows that open something else."""
    registry = (nexus / "PageCompRegistry.qml").read_text()
    pages_dir = nexus / "pages"
    titles = page_titles(pages_dir)

    owned = {}
    for stack in stacks(registry):
        for name in stack:
            owned[name] = stack

    problems = []
    checked = 0
    for path in sorted(pages_dir.rglob("*.qml")):
        stack = owned.get(path.stem)
        if not stack:
            continue
        rel = str(path.relative_to(nexus))
        for label, index in row_blocks(path.read_text()):
            checked += 1
            if index >= len(stack):
                problems.append((rel, label, index, "(outside the stack)"))
                continue
            target = titles.get(stack[index], stack[index])
            want, got = normalise(label), normalise(target)
            if want and got and (want in got or got in want):
                continue
            if (rel, label) in KNOWN:
                continue
            problems.append((rel, label, index, target))
    return checked, problems


def run(nexus):
    checked, problems = scan(nexus)
    for rel, label, index, target in problems:
        print(f"{rel}: '{label}' opens {index} -> '{target}'")
    print(f"{checked} row(s) checked, {len(problems)} mismatch(es)")
    return 1 if problems else 0


FIXTURE_REGISTRY = """\
QtObject {
    readonly property list<Component> pageComps: [
        Component {
            StackPage {
                Component {
                    AlphaPage {}
                }
                Component {
                    BetaPage {}
                }
            }
        }
    ]
}
"""

FIXTURE_PAGE = """\
PageBase {
    title: Tr.tr("Alpha")

    ColumnLayout {
        NavRow {
            text: Tr.tr("Beta")
            onClicked: root.nState.openSubPage(%d)
        }
    }
}
"""


def self_test():
    with tempfile.TemporaryDirectory() as tmp:
        nexus = Path(tmp) / "nexus"
        pages = nexus / "pages"
        pages.mkdir(parents=True)
        (nexus / "PageCompRegistry.qml").write_text(FIXTURE_REGISTRY)
        (pages / "AlphaPage.qml").write_text(FIXTURE_PAGE % 1)
        (pages / "BetaPage.qml").write_text('PageBase {\n    title: Tr.tr("Beta")\n}\n')

        checked, problems = scan(nexus)
        assert checked == 1, f"expected one row, got {checked}"
        assert not problems, f"a correct index was flagged: {problems}"

        (pages / "AlphaPage.qml").write_text(FIXTURE_PAGE % 0)
        checked, problems = scan(nexus)
        assert checked == 1 and len(problems) == 1, (
            f"a wrong index was missed: {problems}"
        )

    print("PASS self-test: flags a wrong index and clears a right one")
    return 0


def main():
    if "--self-test" in sys.argv:
        return self_test()
    return run(NEXUS)


if __name__ == "__main__":
    sys.exit(main())
