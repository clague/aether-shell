pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Shapes
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Aether
import Aether.Config
import Aether.Editor
import Aether.I18n
import qs.components
import qs.components.controls
import qs.services
import qs.utils
import qs.modules.nexus.common

// A small code editor for ~/.config/caelestia/hypr-user.lua: Lua syntax highlighting, line
// numbers, auto-indent, save/reload, and diagnostics + completion from lua-language-server.
PageBase {
    id: root

    readonly property string filePath: `${Paths.config}/hypr-user.lua`
    readonly property bool dirty: editor.text !== root.savedText
    // The top/height of every line, straight from the text layout. Drawing the numbers from the
    // editor's own line positions is what keeps them aligned: font metrics, CJK comments and
    // line spacing can all differ from what a separate Text would assume.
    property var lineRects: []
    // Offset of each line's first character, built alongside lineRects. Position-to-line and
    // line-to-offset lookups are then a binary search instead of a full-text split per call.
    property var lineStarts: []
    property real lineHeight: 1
    property var squiggles: []

    property string savedText: ""
    // The minimap renders the whole document; coalesce updates so typing does not relayout it
    // on every keystroke.
    property string minimapSource: ""
    property string notice: ""
    property string diagnosticTip: ""
    property real diagnosticTipAnchorX: 0
    property real diagnosticTipAnchorY: 0
    property real diagnosticsHeight: 96
    property bool completionOpen: false
    property bool suppressCompletion: false
    // Set while ensureCursorVisible moves the view; scrolling for any other reason closes popups.
    property bool autoScroll: false
    property int completionIndex: 0
    property real completionX: 0
    property real completionY: 0
    readonly property real completionHeight: Math.min(220, Math.max(24, completionList.contentHeight + 8))
    readonly property real completionWidth: flick ? Math.min(340, Math.max(180, flick.width - 16)) : 340
    property bool contextMenuOpen: false
    property real contextMenuX: 0
    property real contextMenuY: 0
    property int caretLine: 0
    property int caretColumn: 0

    function save(): bool {
        root.completionOpen = false;
        root.contextMenuOpen = false;
        root.diagnosticTip = "";
        if (!CUtils.writeFile(root.filePath, editor.text)) {
            root.notice = Tr.tr("Could not write the file");
            noticeTimer.restart();
            return false;
        }
        root.savedText = editor.text;
        root.notice = Tr.tr("Saved");
        noticeTimer.restart();
        return true;
    }

    function revert(): void {
        editor.text = root.savedText;
        editor.cursorPosition = 0;
        flick.contentX = 0;
        flick.contentY = 0;
        root.completionOpen = false;
        root.contextMenuOpen = false;
        root.diagnosticTip = "";
    }

    function insertNewline(): void {
        if (editor.selectionStart !== editor.selectionEnd) {
            const start = editor.selectionStart;
            editor.remove(start, editor.selectionEnd);
            editor.cursorPosition = start;
        }

        const position = editor.cursorPosition;
        const lineStart = root.lineStartAt(position);
        const line = editor.text.slice(lineStart, position);
        const indent = (line.match(/^\s*/) || [""])[0];
        const trimmed = line.replace(/\s+$/, "");
        const opensBlock = /(?:\bthen|\bdo|\bfunction|\brepeat|\belse)\s*$/.test(trimmed) || /[{([]\s*$/.test(trimmed);
        editor.insert(position, "\n" + indent + (opensBlock ? "    " : ""));
    }

    function insertPair(open: string, close: string): void {
        const start = editor.selectionStart;
        const end = editor.selectionEnd;

        if (start !== end) {
            const selected = editor.getText(start, end);
            editor.remove(start, end);
            editor.insert(start, open + selected + close);
            editor.select(start + 1, start + 1 + selected.length);
            return;
        }

        const position = editor.cursorPosition;
        editor.insert(position, open + close);
        editor.cursorPosition = position + 1;
    }

    function skipOver(character: string): bool {
        if (editor.selectionStart === editor.selectionEnd && editor.text[editor.cursorPosition] === character) {
            editor.cursorPosition += 1;
            return true;
        }
        return false;
    }

    // Backspace between an empty pair removes both halves.
    function backspacePair(): bool {
        const position = editor.cursorPosition;
        if (editor.selectionStart !== editor.selectionEnd || position <= 0 || position >= editor.text.length)
            return false;

        const pairs = {
            ")": "(",
            "]": "[",
            "}": "{",
            "\"": "\"",
            "'": "'"
        };
        if (pairs[editor.text[position]] === editor.text[position - 1]) {
            editor.remove(position - 1, position + 1);
            return true;
        }
        return false;
    }

    function lineStartAt(position: int): int {
        return editor.text.lastIndexOf("\n", position - 1) + 1;
    }

    function lineEndAt(position: int): int {
        const end = editor.text.indexOf("\n", position);
        return end < 0 ? editor.text.length : end;
    }

    // Tab indents the current line, or every line the selection touches. Shift+Tab removes one
    // level. The block stays selected, so repeated presses keep working.
    function changeIndent(dedent: bool): void {
        const selStart = editor.selectionStart;
        const selEnd = editor.selectionEnd;
        const hasSelection = selEnd > selStart;
        const first = root.lineStartAt(hasSelection ? selStart : editor.cursorPosition);
        let last = hasSelection ? root.lineStartAt(selEnd) : first;
        if (hasSelection && selEnd === last && last > first)
            last = root.lineStartAt(last - 1);
        const blockEnd = root.lineEndAt(last);

        const lines = editor.text.slice(first, blockEnd).split("\n");
        const updated = lines.map(line => {
            if (!dedent)
                return "    " + line;
            if (line.startsWith("    "))
                return line.slice(4);
            if (line.startsWith("\t"))
                return line.slice(1);
            return line;
        });
        const replacement = updated.join("\n");
        const caret = editor.cursorPosition;

        editor.remove(first, blockEnd);
        editor.insert(first, replacement);

        if (hasSelection)
            editor.select(first, first + replacement.length);
        else
            editor.cursorPosition = Math.max(first, Math.min(first + updated[0].length, caret + updated[0].length - lines[0].length));
    }

    // True when the caret is in code rather than in a comment or a string literal.
    function codeAt(position: int): bool {
        const before = editor.text.slice(root.lineStartAt(position), position);
        let quotes = 0;
        for (let i = 0; i < before.length; i++) {
            if (before[i] === "\\")
                i++;
            else if (before[i] === '"' || before[i] === "'")
                quotes++;
            else if (before[i] === "-" && before[i + 1] === "-" && quotes % 2 === 0)
                return false;
        }
        return quotes % 2 === 0;
    }

    // Completion follows typing: an identifier character, `.` or `:` opens the popup after a
    // short pause. Comments and string literals are skipped, where the server has nothing useful
    // to offer and a popup would only get in the way.
    function shouldAutoComplete(): bool {
        if (lsp.status !== "ready")
            return false;

        const position = editor.cursorPosition;
        if (position <= 0 || position > editor.text.length)
            return false;

        const character = editor.text[position - 1];
        if (!/[A-Za-z0-9_.:]/.test(character))
            return false;

        return root.codeAt(position);
    }

    function requestCompletion(): void {
        // Push the current text first: the completion request must be answered against the same
        // document the caret is in, and the normal sync timer (400 ms) is slower than this one
        // (250 ms). Without this the server completed the previous keystroke's text.
        lsp.sync(editor.text);

        const before = editor.text.slice(0, editor.cursorPosition);
        const line = before.split("\n").length - 1;
        const character = before.length - before.lastIndexOf("\n") - 1;
        lsp.requestCompletion(line, character);
    }

    function updateCompletionPosition(): void {
        if (flick.height <= 0)
            return;

        const rect = editor.cursorRectangle;
        const height = root.completionHeight;
        const caretTop = editor.y + rect.y - flick.contentY;
        const below = caretTop + rect.height + 2;
        const above = caretTop - height - 2;
        const maxX = Math.max(8, gutter.width + flick.width - root.completionWidth - 8);

        root.completionX = Math.max(8, Math.min(gutter.width + editor.x + rect.x - flick.contentX, maxX));
        root.completionY = below + height > flick.height && above >= 0 ? above : Math.max(0, Math.min(below, flick.height - height));
    }

    // Keeps the caret inside the viewport when it moves by keyboard or after a jump (Ctrl+End,
    // clicking a diagnostic, accepting a completion...). The Flickable does not follow the editor
    // on its own.
    function ensureCursorVisible(): void {
        if (flick.height <= 0 || editor.cursorRectangle.height <= 0)
            return;

        scrollXAnimation.stop();
        scrollYAnimation.stop();

        const margin = root.lineHeight * 2;
        const rect = editor.cursorRectangle;
        const top = editor.y + rect.y;
        const bottom = top + rect.height;

        root.autoScroll = true;
        if (top < flick.contentY + margin)
            flick.contentY = Math.max(0, top - margin);
        else if (bottom > flick.contentY + flick.height - margin)
            flick.contentY = Math.min(Math.max(0, flick.contentHeight - flick.height), bottom - flick.height + margin);

        const left = editor.x + rect.x;
        const right = left + Math.max(rect.width, 2);
        if (left < flick.contentX)
            flick.contentX = Math.max(0, left - 24);
        else if (right > flick.contentX + flick.width - 24)
            flick.contentX = Math.min(Math.max(0, flick.contentWidth - flick.width), right - flick.width + 24);
        root.autoScroll = false;
    }

    function lineIndexAt(position: int): int {
        const starts = root.lineStarts;
        if (starts.length === 0)
            return 0;

        let low = 0;
        let high = starts.length - 1;
        while (low <= high) {
            const middle = (low + high) >> 1;
            if (starts[middle] <= position)
                low = middle + 1;
            else
                high = middle - 1;
        }
        return Math.max(0, high);
    }

    function offsetAt(line: int, character: int): int {
        const starts = root.lineStarts;
        if (starts.length === 0)
            return 0;

        const index = Math.max(0, Math.min(line, starts.length - 1));
        const start = starts[index];
        const end = index + 1 < starts.length ? starts[index + 1] - 1 : editor.text.length;
        return start + Math.max(0, Math.min(character, end - start));
    }

    function acceptCompletion(): void {
        const item = lsp.completions[root.completionIndex];
        root.completionOpen = false;
        completionTimer.stop();
        if (!item)
            return;

        let start = editor.cursorPosition;
        let end = start;
        if (item.hasRange) {
            start = root.offsetAt(item.startLine, item.startCharacter);
            end = Math.min(root.offsetAt(item.endLine, item.endCharacter), editor.text.length);
        } else {
            // Only back over the identifier itself: `hl.` must survive, `hl.en` -> `hl.env`.
            while (start > 0 && /[A-Za-z0-9_]/.test(editor.text[start - 1]))
                start--;
        }

        // The insert itself is a text change; asking for completions again would immediately
        // reopen the popup on the word that was just completed.
        root.suppressCompletion = true;
        editor.remove(start, end);
        editor.insert(start, item.insert);
        editor.cursorPosition = start + item.insert.length;
        root.suppressCompletion = false;
    }

    function jumpTo(line: int, character: int): void {
        root.completionOpen = false;
        root.contextMenuOpen = false;
        root.diagnosticTip = "";
        editor.cursorPosition = root.offsetAt(line, character);
        editor.forceActiveFocus();
        root.ensureCursorVisible();
    }

    function recomputeLineRects(): void {
        const text = editor.text;
        const rects = [];
        const starts = [];
        let offset = 0;
        while (true) {
            starts.push(offset);
            const rect = editor.positionToRectangle(offset);
            rects.push({
                top: rect.y,
                height: rect.height
            });
            const next = text.indexOf("\n", offset);
            if (next < 0)
                break;
            offset = next + 1;
        }
        root.lineStarts = starts;
        // Re-assigning the array re-evaluates every line-number binding. Typing inside a line
        // changes the offsets but not the line boxes, so only publish when the boxes moved.
        const unchanged = rects.length === root.lineRects.length && rects.every((rect, index) => {
            const previous = root.lineRects[index];
            return previous && previous.top === rect.top && previous.height === rect.height;
        });
        if (!unchanged)
            root.lineRects = rects;
        root.lineHeight = Math.max(1, rects.length > 0 ? rects[0].height : 1);
    }

    // Exact per-line segments for the diagnostic waves, built from the text layout. Each segment
    // becomes a small Shape below the text (2px stroke); the syntax highlighter only colours text.
    function rebuildSquiggles(): void {
        const lines = editor.text.split("\n");
        const result = [];
        for (let i = 0; i < lsp.diagnostics.length; i++) {
            const diagnostic = lsp.diagnostics[i];
            const colour = root.severityColour(diagnostic.severity);
            for (let line = diagnostic.line; line <= diagnostic.endLine; line++) {
                if (line < 0 || line >= lines.length)
                    continue;
                const lineLength = lines[line].length;
                let from = line === diagnostic.line ? diagnostic.character : 0;
                let to = line === diagnostic.endLine ? diagnostic.endCharacter : lineLength;
                if (diagnostic.line === diagnostic.endLine && diagnostic.character === diagnostic.endCharacter)
                    to = from + 1;
                from = Math.max(0, Math.min(from, lineLength));
                to = Math.max(from, Math.min(to, lineLength));
                if (to <= from)
                    continue;
                const startRect = editor.positionToRectangle(root.offsetAt(line, from));
                // positionToRectangle() returns a caret rect, so use the position *after* the
                // last character; caret width would cut the final glyph off.
                const endRect = editor.positionToRectangle(root.offsetAt(line, to));
                const x1 = startRect.x;
                const x2 = endRect.x;
                if (x2 <= x1)
                    continue;

                result.push({
                    x1: x1,
                    x2: x2,
                    y: startRect.y + startRect.height - 2,
                    colour: colour
                });
            }
        }
        // A clean file rebuilds an empty list on every keystroke; don't churn the Repeater.
        if (result.length === 0 && root.squiggles.length === 0)
            return;
        root.squiggles = result;
    }

    function lineCharacterAt(position: int): var {
        const line = root.lineIndexAt(position);
        return {
            line: line,
            character: position - (root.lineStarts[line] ?? 0)
        };
    }

    function diagnosticContains(diagnostic: var, line: int, character: int): bool {
        const afterStart = line > diagnostic.line || (line === diagnostic.line && character >= diagnostic.character);
        const point = diagnostic.line === diagnostic.endLine && diagnostic.character === diagnostic.endCharacter;
        const beforeEnd = point ? line === diagnostic.endLine && character <= diagnostic.endCharacter : line < diagnostic.endLine || (line === diagnostic.endLine && character < diagnostic.endCharacter);
        return afterStart && beforeEnd;
    }

    // Hovering a squiggle/underlined range shows its language-server message next to the pointer.
    function showDiagnosticTip(x: real, y: real): void {
        // While text is selected the selection tip wins; a stationary pointer must not clear it
        // when the view scrolls under it.
        if (editor.selectionStart !== editor.selectionEnd)
            return;

        if (root.completionOpen) {
            root.diagnosticTip = "";
            return;
        }

        // positionAt() returns the nearest caret position, which is the cell to the right when
        // the pointer is in the right half of an underlined character. Check both.
        const position = editor.positionAt(x, y);
        const messages = [];
        for (let i = 0; i < lsp.diagnostics.length; i++) {
            const diagnostic = lsp.diagnostics[i];
            let hit = false;
            for (const candidate of [position, position - 1]) {
                if (candidate < 0)
                    continue;
                const at = root.lineCharacterAt(candidate);
                if (root.diagnosticContains(diagnostic, at.line, at.character)) {
                    hit = true;
                    break;
                }
            }
            if (hit)
                messages.push(diagnostic.message);
        }
        if (messages.length === 0) {
            root.diagnosticTip = "";
            return;
        }

        root.diagnosticTipAnchorX = gutter.width + editor.x + x - flick.contentX;
        root.diagnosticTipAnchorY = editor.y + y - flick.contentY;
        root.diagnosticTip = messages.join("\n\n");
    }

    function diagnosticIntersects(diagnostic: var, startLine: int, startCharacter: int, endLine: int, endCharacter: int): bool {
        const afterStart = diagnostic.endLine > startLine || (diagnostic.endLine === startLine && diagnostic.endCharacter >= startCharacter);
        const beforeEnd = diagnostic.line < endLine || (diagnostic.line === endLine && diagnostic.character <= endCharacter);
        return afterStart && beforeEnd;
    }

    // Selecting a range that overlaps a problem also shows its message, not just hovering.
    function showDiagnosticTipForSelection(): void {
        if (editor.selectionStart === editor.selectionEnd)
            return;

        const start = Math.min(editor.selectionStart, editor.selectionEnd);
        const end = Math.max(editor.selectionStart, editor.selectionEnd);
        const from = root.lineCharacterAt(start);
        const to = root.lineCharacterAt(end);
        const messages = [];
        for (let i = 0; i < lsp.diagnostics.length; i++) {
            const diagnostic = lsp.diagnostics[i];
            if (root.diagnosticIntersects(diagnostic, from.line, from.character, to.line, to.character))
                messages.push(diagnostic.message);
        }

        if (messages.length === 0) {
            root.diagnosticTip = "";
            return;
        }

        const rect = editor.cursorRectangle;
        root.diagnosticTipAnchorX = gutter.width + editor.x + rect.x - flick.contentX;
        root.diagnosticTipAnchorY = editor.y + rect.y + rect.height - flick.contentY;
        root.diagnosticTip = messages.join("\n\n");
    }

    function closePopupsOnScroll(): void {
        if (root.completionOpen)
            root.completionOpen = false;
        root.contextMenuOpen = false;
        root.diagnosticTip = "";
    }

    // One wheel notch is three lines in Qt Quick (QStyleHints::wheelScrollLines() * 24 px).
    // A Wayland mouse wheel also reports a much smaller pixelDelta; preferring that moved only
    // a fraction of a line per notch. Touchpads report pixelDelta only, so they stay smooth.
    function wheelDelta(wheel: var): real {
        return wheel.angleDelta.y !== 0 ? wheel.angleDelta.y / 120 * 72 : wheel.pixelDelta.y;
    }

    function scrollEditorBy(pixels: real, horizontal: bool, smooth: bool): void {
        if (smooth) {
            // A clicky wheel scrolls three lines at once; ease there like the scrollbar does.
            // When another notch arrives mid-animation, add it to the pending target so fast
            // wheeling keeps its speed instead of restarting from the current position.
            if (horizontal)
                root.animateScrollX((scrollXAnimation.running ? scrollXAnimation.to : flick.contentX) - pixels);
            else
                root.animateScrollY((scrollYAnimation.running ? scrollYAnimation.to : flick.contentY) - pixels);
            return;
        }

        // Pixel deltas come in a continuous stream from a touchpad; applying them immediately
        // (instead of starting an animation per event) is what keeps that scrolling smooth.
        scrollXAnimation.stop();
        scrollYAnimation.stop();
        if (horizontal) {
            const maxX = Math.max(0, flick.contentWidth - flick.width);
            flick.contentX = Math.max(0, Math.min(flick.contentX - pixels, maxX));
        } else {
            const maxY = Math.max(0, flick.contentHeight - flick.height);
            flick.contentY = Math.max(0, Math.min(flick.contentY - pixels, maxY));
        }
    }

    function refreshCaret(): void {
        const position = Math.max(0, editor.cursorPosition);
        const line = root.lineIndexAt(position);
        root.caretLine = line;
        root.caretColumn = position - (root.lineStarts[line] ?? 0);
    }

    function undoEdit(): void {
        root.completionOpen = false;
        root.diagnosticTip = "";
        // Undoing changes the text, which would otherwise reopen the completion popup on the
        // character that has just been restored.
        root.suppressCompletion = true;
        editor.undo();
        root.suppressCompletion = false;
        root.ensureCursorVisible();
    }

    function redoEdit(): void {
        root.completionOpen = false;
        root.diagnosticTip = "";
        root.suppressCompletion = true;
        editor.redo();
        root.suppressCompletion = false;
        root.ensureCursorVisible();
    }

    // Ctrl+Backspace / Ctrl+Delete. TextEdit does not implement word deletion itself.
    function deleteWord(forward: bool): void {
        const selectedStart = editor.selectionStart;
        const selectedEnd = editor.selectionEnd;
        if (selectedStart !== selectedEnd) {
            editor.remove(selectedStart, selectedEnd);
            editor.cursorPosition = selectedStart;
            return;
        }

        const text = editor.text;
        const position = editor.cursorPosition;
        let target = position;
        if (forward) {
            while (target < text.length && !/[A-Za-z0-9_]/.test(text[target]))
                target++;
            while (target < text.length && /[A-Za-z0-9_]/.test(text[target]))
                target++;
        } else {
            while (target > 0 && !/[A-Za-z0-9_]/.test(text[target - 1]))
                target--;
            while (target > 0 && /[A-Za-z0-9_]/.test(text[target - 1]))
                target--;
        }
        if (target === position)
            return;

        editor.remove(Math.min(position, target), Math.max(position, target));
        editor.cursorPosition = Math.min(position, target);
    }

    function placeCaret(panelX: real, panelY: real): void {
        editor.forceActiveFocus();
        // The catcher is in panel coordinates; the editor lives at (editor.x, editor.y) inside
        // the flick's scrollable content, one gutter to the right of the panel's origin.
        const textX = panelX - gutter.width + flick.contentX - editor.x;
        const textY = panelY + flick.contentY - editor.y;
        const position = editor.positionAt(textX, textY);
        const from = Math.min(editor.selectionStart, editor.selectionEnd);
        const to = Math.max(editor.selectionStart, editor.selectionEnd);
        // Right-clicking inside a selection keeps it; anywhere else moves the caret there, so
        // Paste and Undo act where the user clicked (as editors do).
        if (position < from || position > to)
            editor.cursorPosition = position;
    }

    function openContextMenu(x: real, y: real): void {
        root.completionOpen = false;
        root.diagnosticTip = "";
        root.contextMenuX = x;
        root.contextMenuY = y;
        root.contextMenuOpen = true;
    }

    function contextActionLabel(action: string): string {
        switch (action) {
        case "undo":
            return Tr.tr("Undo");
        case "redo":
            return Tr.tr("Redo");
        case "cut":
            return Tr.tr("Cut");
        case "copy":
            return Tr.tr("Copy");
        case "paste":
            return Tr.tr("Paste");
        case "selectAll":
            return Tr.tr("Select all");
        }
        return "";
    }

    function contextActionEnabled(action: string): bool {
        switch (action) {
        case "undo":
            return editor.canUndo;
        case "redo":
            return editor.canRedo;
        case "cut":
        case "copy":
            return editor.selectedText.length > 0;
        case "paste":
            return editor.canPaste;
        case "selectAll":
            return editor.length > 0;
        }
        return false;
    }

    function runContextAction(action: string): void {
        root.contextMenuOpen = false;
        switch (action) {
        case "undo":
            root.undoEdit();
            break;
        case "redo":
            root.redoEdit();
            break;
        case "cut":
            editor.cut();
            break;
        case "copy":
            editor.copy();
            break;
        case "paste":
            editor.paste();
            break;
        case "selectAll":
            editor.selectAll();
            break;
        }
        editor.forceActiveFocus();
    }

    function animateScrollX(target: real): void {
        scrollXAnimation.stop();
        scrollXAnimation.from = flick.contentX;
        scrollXAnimation.to = Math.max(0, Math.min(target, Math.max(0, flick.contentWidth - flick.width)));
        scrollXAnimation.start();
    }

    function animateScrollY(target: real): void {
        scrollYAnimation.stop();
        scrollYAnimation.from = flick.contentY;
        scrollYAnimation.to = Math.max(0, Math.min(target, Math.max(0, flick.contentHeight - flick.height)));
        scrollYAnimation.start();
    }

    function severityColour(severity: int): color {
        if (severity === 1)
            return Colours.palette.m3error;
        if (severity === 2)
            return Colours.palette.m3tertiary;
        return Colours.palette.m3secondary;
    }

    title: Tr.tr("User configuration")
    isSubPage: true
    scrollable: false

    Component.onCompleted: {
        lsp.start();
        // The window opens with the settings search focused; the editor should have the caret.
        Qt.callLater(() => editor.forceActiveFocus());
    }

    onDirtyChanged: {
        if (lsp.status === "ready")
            syncTimer.restart();
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Tokens.padding.large
        spacing: Tokens.spacing.small

        FileView {
            id: configFile

            path: root.filePath

            onLoaded: {
                const content = text();
                root.savedText = content;
                editor.text = content;
                root.minimapSource = content;
            }
        }

        LuaHighlighter {
            textDocument: editor.textDocument
            keywordColor: Colours.palette.m3primary
            builtinColor: Colours.palette.m3secondary
            stringColor: Colours.palette.m3tertiary
            numberColor: Colours.palette.m3error
            commentColor: Colours.palette.m3outline
        }

        LuaLsp {
            id: lsp

            filePath: root.filePath
            libraryPath: Quickshell.shellPath("assets/lua")

            onStatusChanged: {
                if (status === "ready")
                    lsp.open(editor.text);
            }

            onCompletionsChanged: {
                if (completions.length > 0) {
                    root.diagnosticTip = "";
                    root.contextMenuOpen = false;
                    root.completionIndex = 0;
                    root.completionOpen = true;
                    root.updateCompletionPosition();
                    Qt.callLater(root.updateCompletionPosition);
                } else {
                    root.completionOpen = false;
                }
            }

            onDiagnosticsChanged: {
                root.diagnosticTip = "";
                root.rebuildSquiggles();
                // The panel takes height away from the editor once the view has been laid out.
                Qt.callLater(root.ensureCursorVisible);
            }
        }

        Timer {
            id: syncTimer

            interval: 400
            onTriggered: lsp.sync(editor.text)
        }

        Timer {
            id: noticeTimer

            interval: 2500
            onTriggered: root.notice = ""
        }

        Timer {
            id: completionTimer

            interval: 250
            onTriggered: root.requestCompletion()
        }

        Timer {
            id: minimapTimer

            interval: 120
            onTriggered: {
                if (root.minimapSource !== editor.text)
                    root.minimapSource = editor.text;
            }
        }

        Process {
            id: reloadProc

            command: ["hyprctl", "reload"]

            onExited: {
                root.notice = Tr.tr("Applied to Hyprland");
                noticeTimer.restart();
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: Tokens.spacing.small

            StyledText {
                Layout.fillWidth: true
                text: root.filePath
                color: Colours.palette.m3onSurfaceVariant
                font: Tokens.font.label.small
                elide: Text.ElideMiddle
            }

            StyledText {
                visible: lsp.status === "unavailable"
                text: Tr.tr("lua-language-server is not installed")
                color: Colours.palette.m3error
                font: Tokens.font.label.small
            }

            StyledText {
                visible: lsp.status === "starting"
                text: Tr.tr("Starting language server…")
                color: Colours.palette.m3onSurfaceVariant
                font: Tokens.font.label.small
            }

            StyledText {
                visible: root.dirty
                text: Tr.tr("Unsaved changes")
                color: Colours.palette.m3tertiary
                font: Tokens.font.label.small
            }

            StyledText {
                visible: root.notice !== ""
                text: root.notice
                color: Colours.palette.m3primary
                font: Tokens.font.label.small
            }

            IconTextButton {
                icon: "undo"
                text: Tr.tr("Revert")
                type: TextButton.Text
                enabled: root.dirty
                onClicked: root.revert()
            }

            IconTextButton {
                icon: "restart_alt"
                text: Tr.tr("Apply to Hyprland")
                type: TextButton.Tonal
                onClicked: {
                    root.completionOpen = false;
                    root.contextMenuOpen = false;
                    if (root.dirty && !root.save())
                        return;
                    reloadProc.running = true;
                }
            }

            IconTextButton {
                icon: "save"
                text: Tr.tr("Save")
                type: TextButton.Filled
                enabled: root.dirty
                onClicked: root.save()
            }
        }

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            NumberAnimation {
                id: scrollXAnimation

                target: flick
                property: "contentX"
                duration: 140
                easing.type: Easing.OutCubic
            }

            NumberAnimation {
                id: scrollYAnimation

                target: flick
                property: "contentY"
                duration: 140
                easing.type: Easing.OutCubic
            }

            Rectangle {
                anchors.fill: parent
                radius: Tokens.rounding.large
                color: Qt.alpha(Colours.palette.m3surfaceContainerLow, 0.65)
                border.width: 1
                border.color: Qt.alpha(Colours.palette.m3outlineVariant, 0.4)
                clip: true
            }

            Item {
                id: gutter

                anchors.left: parent.left
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                width: 52
                clip: true

                Repeater {
                    // The count comes from the document; the positions come from lineRects so the
                    // delegates are only recreated when a line is added or removed.
                    model: editor.lineCount

                    Text {
                        required property int index

                        x: 10
                        y: editor.y + (root.lineRects[index] ? root.lineRects[index].top : index * root.lineHeight) - flick.contentY
                        text: index + 1
                        color: Qt.alpha(Colours.palette.m3onSurfaceVariant, 0.7)
                        font: editor.font
                    }
                }

                Repeater {
                    model: lsp.diagnostics

                    Rectangle {
                        id: gutterMarker

                        required property var modelData

                        x: 4
                        y: {
                            const rect = root.lineRects[gutterMarker.modelData.line];
                            const top = rect ? rect.top : gutterMarker.modelData.line * root.lineHeight;
                            const height = rect ? rect.height : root.lineHeight;
                            return editor.y + top + (height - 5) / 2 - flick.contentY;
                        }
                        width: 5
                        height: 5
                        radius: 2.5
                        color: root.severityColour(gutterMarker.modelData.severity)
                    }
                }
            }

            Flickable {
                id: flick

                anchors.left: gutter.right
                anchors.right: minimap.left
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                clip: true
                boundsBehavior: Flickable.StopAtBounds
                contentWidth: editor.contentWidth + 24
                contentHeight: editor.contentHeight + 20

                onContentHeightChanged: {
                    if (editor.activeFocus)
                        root.ensureCursorVisible();
                }

                onContentYChanged: {
                    if (!root.autoScroll)
                        root.closePopupsOnScroll();
                }

                onContentXChanged: {
                    if (!root.autoScroll)
                        root.closePopupsOnScroll();
                }

                Rectangle {
                    x: 0
                    y: editor.y + editor.cursorRectangle.y
                    width: flick.contentWidth
                    height: editor.cursorRectangle.height
                    color: Qt.alpha(Colours.palette.m3primary, 0.05)
                }

                Repeater {
                    model: root.squiggles

                    Shape {
                        id: waveShape

                        required property var modelData

                        x: editor.x + modelData.x1
                        y: editor.y + modelData.y - 2
                        width: modelData.x2 - modelData.x1
                        height: 5
                        z: -1

                        ShapePath {
                            strokeColor: waveShape.modelData.colour
                            strokeWidth: 2
                            fillColor: "transparent"
                            capStyle: ShapePath.RoundCap
                            joinStyle: ShapePath.RoundJoin

                            PathPolyline {
                                path: {
                                    const points = [];
                                    const width = waveShape.modelData.x2 - waveShape.modelData.x1;
                                    for (let x = 0; x <= width; x += 0.5)
                                        points.push(Qt.point(x, 2 + Math.sin((x / 6) * Math.PI * 2) * 1.6));
                                    return points;
                                }
                            }
                        }
                    }
                }

                TextEdit {
                    id: editor

                    x: 12
                    y: 10
                    width: Math.max(flick.width - 24, contentWidth)
                    // Fill the viewport even when the file is shorter, so a click below the last
                    // line still places the caret (at the end) instead of doing nothing.
                    height: Math.max(contentHeight, flick.height)

                    color: Colours.palette.m3onSurface
                    selectionColor: Qt.alpha(Colours.palette.m3primary, 0.35)
                    selectedTextColor: Colours.palette.m3onSurface
                    font: Tokens.font.mono.medium
                    wrapMode: TextEdit.NoWrap
                    selectByMouse: true
                    focus: true

                    onTextChanged: {
                        root.diagnosticTip = "";
                        minimapTimer.restart();
                        root.recomputeLineRects();
                        root.rebuildSquiggles();
                        root.refreshCaret();
                        // Only a changed line count can make the synchronous layout pass stale;
                        // typing inside a line keeps every line's position and height.
                        if (root.lineRects.length !== editor.lineCount) {
                            Qt.callLater(root.recomputeLineRects);
                            Qt.callLater(root.rebuildSquiggles);
                        }
                        if (lsp.status === "ready")
                            syncTimer.restart();
                        if (!root.suppressCompletion) {
                            if (root.shouldAutoComplete())
                                completionTimer.restart();
                            else if (root.completionOpen)
                                root.completionOpen = false;
                        }
                    }

                    onContentHeightChanged: {
                        root.recomputeLineRects();
                        root.rebuildSquiggles();
                    }

                    onFontChanged: {
                        root.recomputeLineRects();
                        root.rebuildSquiggles();
                    }

                    onSelectedTextChanged: {
                        if (editor.selectedText !== "")
                            root.showDiagnosticTipForSelection();
                    }

                    onCursorPositionChanged: {
                        root.refreshCaret();
                        if (root.completionOpen)
                            root.updateCompletionPosition();
                        root.ensureCursorVisible();
                        // contentHeight can lag one frame behind a new line; scroll again once it
                        // has grown, otherwise the last line stays half-clipped at the bottom.
                        Qt.callLater(root.ensureCursorVisible);
                    }

                    Keys.onPressed: event => {
                        if (root.contextMenuOpen && event.key === Qt.Key_Escape) {
                            root.contextMenuOpen = false;
                            event.accepted = true;
                            return;
                        }

                        if (root.completionOpen) {
                            if (event.key === Qt.Key_Down) {
                                root.completionIndex = Math.min(root.completionIndex + 1, lsp.completions.length - 1);
                                event.accepted = true;
                                return;
                            }
                            if (event.key === Qt.Key_Up) {
                                root.completionIndex = Math.max(root.completionIndex - 1, 0);
                                event.accepted = true;
                                return;
                            }
                            if (event.key === Qt.Key_Escape) {
                                root.completionOpen = false;
                                event.accepted = true;
                                return;
                            }
                            if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Tab) {
                                root.acceptCompletion();
                                event.accepted = true;
                                return;
                            }
                        }

                        if (event.key === Qt.Key_Escape && root.diagnosticTip !== "") {
                            root.diagnosticTip = "";
                            event.accepted = true;
                            return;
                        }

                        if (event.modifiers & Qt.ControlModifier) {
                            if (event.key === Qt.Key_S) {
                                root.save();
                                event.accepted = true;
                                return;
                            }
                            if (event.key === Qt.Key_Space) {
                                root.requestCompletion();
                                event.accepted = true;
                                return;
                            }
                            if (event.key === Qt.Key_Z) {
                                if (event.modifiers & Qt.ShiftModifier)
                                    root.redoEdit();
                                else
                                    root.undoEdit();
                                event.accepted = true;
                                return;
                            }
                            if (event.key === Qt.Key_Y) {
                                root.redoEdit();
                                event.accepted = true;
                                return;
                            }
                            if (event.key === Qt.Key_Backspace || event.key === Qt.Key_Delete) {
                                root.deleteWord(event.key === Qt.Key_Delete);
                                event.accepted = true;
                                return;
                            }
                        }

                        if (event.key === Qt.Key_Backspace && root.backspacePair()) {
                            event.accepted = true;
                            return;
                        }

                        const pairs = {
                            "(": ")",
                            "[": "]",
                            "{": "}",
                            "\"": "\"",
                            "'": "'"
                        };
                        if (pairs[event.text] !== undefined && root.codeAt(editor.cursorPosition)) {
                            if ((event.text === "\"" || event.text === "'") && root.skipOver(event.text)) {
                                event.accepted = true;
                                return;
                            }
                            root.insertPair(event.text, pairs[event.text]);
                            event.accepted = true;
                            return;
                        }
                        if ((event.text === ")" || event.text === "]" || event.text === "}") && root.skipOver(event.text)) {
                            event.accepted = true;
                            return;
                        }

                        if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                            root.insertNewline();
                            event.accepted = true;
                            return;
                        }
                        if (event.key === Qt.Key_Tab) {
                            root.changeIndent(false);
                            event.accepted = true;
                            return;
                        }
                        if (event.key === Qt.Key_Backtab) {
                            root.changeIndent(true);
                            event.accepted = true;
                        }
                    }

                    onActiveFocusChanged: {
                        if (!activeFocus) {
                            root.completionOpen = false;
                            root.contextMenuOpen = false;
                            root.diagnosticTip = "";
                        }
                    }

                    HoverHandler {
                        id: editorHover

                        onPointChanged: root.showDiagnosticTip(editorHover.point.position.x, editorHover.point.position.y)

                        onHoveredChanged: {
                            if (!hovered && editor.selectionStart === editor.selectionEnd)
                                root.diagnosticTip = "";
                        }
                    }
                }
            }

            MouseArea {
                id: editorPressCatcher

                anchors.fill: parent
                acceptedButtons: Qt.AllButtons
                // The catcher sits above the TextEdit, so it has to supply the I-beam itself.
                // A plain cursorShape (no hoverEnabled) leaves the TextEdit's HoverHandler free
                // for the diagnostic tooltips.
                cursorShape: Qt.IBeamCursor

                // Close popups on press, not release, and let the press reach the TextEdit so
                // caret placement and drag-selection still work.
                onPressed: mouse => {
                    root.completionOpen = false;
                    root.diagnosticTip = "";

                    if (mouse.button === Qt.RightButton) {
                        root.placeCaret(mouse.x, mouse.y);
                        root.openContextMenu(mouse.x, mouse.y);
                        mouse.accepted = true;
                        return;
                    }

                    root.contextMenuOpen = false;
                    mouse.accepted = false;
                }

                onWheel: wheel => {
                    const delta = root.wheelDelta(wheel);
                    if (delta === 0) {
                        wheel.accepted = false;
                        return;
                    }
                    root.scrollEditorBy(delta, (wheel.modifiers & Qt.ShiftModifier) !== 0, wheel.angleDelta.y !== 0);
                    wheel.accepted = true;
                }
            }

            // Line numbers get the normal arrow, not the text I-beam. The area accepts no
            // buttons, so presses still reach the catcher below and wheels still scroll.
            MouseArea {
                id: gutterCursor

                anchors.left: parent.left
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                width: gutter.width
                acceptedButtons: Qt.NoButton
                cursorShape: Qt.ArrowCursor

                onWheel: wheel => {
                    const delta = root.wheelDelta(wheel);
                    if (delta === 0) {
                        wheel.accepted = false;
                        return;
                    }
                    root.scrollEditorBy(delta, (wheel.modifiers & Qt.ShiftModifier) !== 0, wheel.angleDelta.y !== 0);
                    wheel.accepted = true;
                }
            }

            Item {
                id: horizontalScrollBar

                anchors.left: flick.left
                anchors.right: flick.right
                anchors.bottom: flick.bottom
                height: 8
                visible: flick.contentWidth > flick.width

                function contentForThumbCenter(x: real): real {
                    const travel = Math.max(1, width - horizontalThumb.width);
                    const ratio = Math.max(0, Math.min(1, (x - horizontalThumb.width / 2) / travel));
                    return ratio * Math.max(0, flick.contentWidth - flick.width);
                }

                function trackScroll(x: real): real {
                    const target = contentForThumbCenter(x);
                    root.animateScrollX(target);
                    return target;
                }

                Rectangle {
                    anchors.fill: parent
                    radius: 4
                    color: Qt.alpha(Colours.palette.m3onSurfaceVariant, 0.08)
                }

                Rectangle {
                    id: horizontalThumb

                    readonly property real ratio: flick.contentWidth > flick.width ? flick.width / flick.contentWidth : 1

                    height: parent.height
                    width: Math.max(24, parent.width * ratio)
                    x: (parent.width - width) * (flick.contentX / Math.max(1, flick.contentWidth - flick.width))
                    radius: 4
                    color: Qt.alpha(Colours.palette.m3secondary, 0.7)
                }

                MouseArea {
                    id: horizontalScrollArea

                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor

                    property real pressX: 0
                    property real pressContentX: 0
                    property bool draggingThumb: false

                    onPressed: mouse => {
                        root.completionOpen = false;
                        root.contextMenuOpen = false;
                        root.diagnosticTip = "";
                        scrollXAnimation.stop();
                        const thumb = horizontalThumb;
                        if (mouse.x >= thumb.x && mouse.x <= thumb.x + thumb.width) {
                            draggingThumb = true;
                            pressX = mouse.x;
                            pressContentX = flick.contentX;
                        } else {
                            draggingThumb = false;
                            pressX = mouse.x;
                            pressContentX = horizontalScrollBar.trackScroll(mouse.x);
                        }
                    }

                    onPositionChanged: mouse => {
                        if (!pressed)
                            return;

                        // A press on the empty track starts the animated jump, but moving before
                        // releasing switches to dragging: the thumb follows the pointer.
                        const travel = Math.max(1, width - horizontalThumb.width);
                        const max = Math.max(0, flick.contentWidth - flick.width);
                        const delta = mouse.x - pressX;

                        if (!draggingThumb) {
                            // Track press: the click anchored at the (clamped) target; any
                            // movement from the click point scrolls immediately, even at edges.
                            scrollXAnimation.stop();
                            flick.contentX = Math.max(0, Math.min(pressContentX + delta / travel * max, max));
                            return;
                        }

                        flick.contentX = Math.max(0, Math.min(pressContentX + delta / travel * max, max));
                    }

                    onReleased: draggingThumb = false
                }
            }

            Rectangle {
                id: minimap

                anchors.top: parent.top
                anchors.bottom: parent.bottom
                anchors.right: parent.right
                width: 84
                radius: Tokens.rounding.large
                color: Qt.alpha(Colours.palette.m3surfaceContainerLowest, 0.35)
                border.width: 1
                border.color: Qt.alpha(Colours.palette.m3outlineVariant, 0.35)
                clip: true

                readonly property real mapHeight: Math.min(height - 8, minimapText.contentHeight)

                function contentForBoxCenter(y: real): real {
                    const travel = Math.max(1, mapHeight - minimapViewport.height);
                    const ratio = Math.max(0, Math.min(1, (y - 4 - minimapViewport.height / 2) / travel));
                    return ratio * Math.max(0, flick.contentHeight - flick.height);
                }

                function trackScroll(y: real): real {
                    const target = contentForBoxCenter(y);
                    root.animateScrollY(target);
                    return target;
                }

                Text {
                    id: minimapText

                    x: 6
                    y: 4
                    width: parent.width - 12
                    text: root.minimapSource
                    color: Qt.alpha(Colours.palette.m3onSurface, 0.55)
                    font.family: editor.font.family
                    font.pixelSize: Math.max(1, Math.min(3, (parent.height - 8) / Math.max(1, editor.lineCount) / 1.25))
                    wrapMode: Text.NoWrap
                    clip: true
                    textFormat: Text.PlainText
                    renderType: Text.QtRendering
                }

                Rectangle {
                    id: minimapViewport

                    x: 2
                    width: parent.width - 4
                    height: Math.max(8, Math.min(minimap.mapHeight, (flick.height / Math.max(1, flick.contentHeight)) * minimap.mapHeight))
                    y: 4 + (flick.contentY / Math.max(1, flick.contentHeight - flick.height)) * Math.max(0, minimap.mapHeight - height)
                    color: Qt.alpha(Colours.palette.m3primary, 0.12)
                    border.width: 1
                    border.color: Qt.alpha(Colours.palette.m3primary, 0.4)
                    radius: 2
                }

                MouseArea {
                    id: minimapScrollArea

                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor

                    property real pressY: 0
                    property real pressContentY: 0
                    property bool draggingBox: false

                    onPressed: mouse => {
                        root.completionOpen = false;
                        root.contextMenuOpen = false;
                        root.diagnosticTip = "";
                        scrollYAnimation.stop();
                        const box = minimapViewport;
                        if (mouse.y >= box.y && mouse.y <= box.y + box.height) {
                            draggingBox = true;
                            pressY = mouse.y;
                            pressContentY = flick.contentY;
                        } else {
                            draggingBox = false;
                            pressY = mouse.y;
                            pressContentY = minimap.trackScroll(mouse.y);
                        }
                    }

                    onPositionChanged: mouse => {
                        if (!pressed)
                            return;

                        // A press outside the viewport box starts the animated jump; moving
                        // before releasing drags the box to the pointer instead.
                        const travel = Math.max(1, minimap.mapHeight - minimapViewport.height);
                        const max = Math.max(0, flick.contentHeight - flick.height);
                        const delta = mouse.y - pressY;

                        if (!draggingBox) {
                            // Track press: anchored at the clamped target; movement from the
                            // click scrolls immediately, without crossing the box centre.
                            scrollYAnimation.stop();
                            flick.contentY = Math.max(0, Math.min(pressContentY + delta / travel * max, max));
                            return;
                        }

                        flick.contentY = Math.max(0, Math.min(pressContentY + delta / travel * max, max));
                    }

                    onReleased: draggingBox = false
                }
            }

            StyledRect {
                id: completionPopup

                x: root.completionX
                y: root.completionY
                width: root.completionWidth
                height: root.completionHeight
                visible: root.completionOpen && lsp.completions.length > 0
                z: 10
                radius: Tokens.rounding.medium
                color: Colours.palette.m3surfaceContainerHigh

                // The editor's I-beam would otherwise show through the popup; keep the normal
                // arrow here and let the ListView still receive the wheel.
                MouseArea {
                    anchors.fill: parent
                    acceptedButtons: Qt.NoButton
                    cursorShape: Qt.ArrowCursor

                    onWheel: wheel => wheel.accepted = false
                }

                ListView {
                    id: completionList

                    anchors.fill: parent
                    anchors.margins: 4
                    clip: true
                    model: lsp.completions
                    currentIndex: root.completionIndex

                    onContentHeightChanged: {
                        if (root.completionOpen)
                            root.updateCompletionPosition();
                    }

                    // Keep the keyboard selection visible in long completion lists.
                    onCurrentIndexChanged: {
                        if (root.completionOpen && currentIndex >= 0)
                            positionViewAtIndex(currentIndex, ListView.Contain);
                    }

                    highlight: StyledRect {
                        radius: Tokens.rounding.small
                        color: Qt.alpha(Colours.palette.m3primary, 0.16)
                    }

                    delegate: Item {
                        id: completionItem

                        required property var modelData
                        required property int index

                        width: completionList.width
                        height: 24

                        StyledText {
                            anchors.left: parent.left
                            anchors.leftMargin: 8
                            anchors.verticalCenter: parent.verticalCenter
                            width: parent.width * 0.45
                            text: completionItem.modelData.label
                            elide: Text.ElideRight
                            font: Tokens.font.mono.small
                        }

                        StyledText {
                            anchors.left: parent.left
                            anchors.leftMargin: parent.width * 0.45 + 12
                            anchors.right: parent.right
                            anchors.rightMargin: 8
                            anchors.verticalCenter: parent.verticalCenter
                            text: completionItem.modelData.detail
                            color: Colours.palette.m3onSurfaceVariant
                            elide: Text.ElideRight
                            font: Tokens.font.label.small
                        }

                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor

                            onEntered: root.completionIndex = completionItem.index

                            onClicked: {
                                root.completionIndex = completionItem.index;
                                root.acceptCompletion();
                            }
                        }
                    }
                }
            }

            Rectangle {
                id: diagnosticTipPopup

                readonly property real tipWidth: Math.min(380, Math.max(160, flick.width - 16))
                readonly property real below: root.diagnosticTipAnchorY + 22

                x: Math.max(8, Math.min(root.diagnosticTipAnchorX + 14, Math.max(8, flick.width - tipWidth)))
                y: below + height > flick.height ? Math.max(0, root.diagnosticTipAnchorY - height - 12) : below
                width: tipWidth
                height: diagnosticTipText.contentHeight + Tokens.padding.medium * 2
                visible: root.diagnosticTip !== ""
                z: 11
                radius: Tokens.rounding.medium
                color: Colours.palette.m3surfaceContainerHigh
                border.width: 1
                border.color: Qt.alpha(Colours.palette.m3outlineVariant, 0.6)

                StyledText {
                    id: diagnosticTipText

                    x: Tokens.padding.medium
                    y: Tokens.padding.medium
                    width: parent.width - Tokens.padding.medium * 2
                    text: root.diagnosticTip
                    wrapMode: Text.Wrap
                    font: Tokens.font.label.small
                }

                MouseArea {
                    anchors.fill: parent
                    acceptedButtons: Qt.NoButton
                    cursorShape: Qt.ArrowCursor

                    onWheel: wheel => wheel.accepted = false
                }
            }

            Rectangle {
                id: contextMenu

                readonly property int rowHeight: 30

                x: Math.max(8, Math.min(root.contextMenuX, parent.width - width - 8))
                y: Math.max(8, Math.min(root.contextMenuY, parent.height - height - 8))
                width: 180
                height: contextColumn.implicitHeight + Tokens.padding.extraSmall * 2
                visible: root.contextMenuOpen
                z: 20
                radius: Tokens.rounding.medium
                color: Colours.palette.m3surfaceContainerHigh
                border.width: 1
                border.color: Qt.alpha(Colours.palette.m3outlineVariant, 0.6)

                // Swallow presses and wheels: the editor underneath must not move the caret or
                // close the menu while one of its rows is being used.
                MouseArea {
                    anchors.fill: parent

                    onPressed: mouse => mouse.accepted = true
                    onWheel: wheel => wheel.accepted = true
                }

                Column {
                    id: contextColumn

                    x: Tokens.padding.extraSmall
                    y: Tokens.padding.extraSmall
                    width: parent.width - Tokens.padding.extraSmall * 2
                    spacing: 0

                    Repeater {
                        model: ["undo", "redo", "cut", "copy", "paste", "selectAll"]

                        Rectangle {
                            id: contextRow

                            required property string modelData
                            readonly property bool available: root.contextActionEnabled(modelData)

                            width: contextColumn.width
                            height: contextMenu.rowHeight
                            radius: Tokens.rounding.small
                            color: contextHover.hovered && contextRow.available ? Qt.alpha(Colours.palette.m3onSurface, 0.08) : "transparent"

                            HoverHandler {
                                id: contextHover
                            }

                            StyledText {
                                anchors.left: parent.left
                                anchors.leftMargin: Tokens.padding.medium
                                anchors.verticalCenter: parent.verticalCenter
                                text: root.contextActionLabel(contextRow.modelData)
                                opacity: contextRow.available ? 1 : 0.38
                                font: Tokens.font.label.medium
                            }

                            MouseArea {
                                anchors.fill: parent
                                enabled: contextRow.available
                                cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor

                                onClicked: root.runContextAction(contextRow.modelData)
                            }
                        }
                    }
                }
            }
        }

        Rectangle {
            id: diagnosticsHandle

            Layout.fillWidth: true
            Layout.preferredHeight: visible ? 12 : 0
            visible: lsp.diagnostics.length > 0
            color: "transparent"

            Rectangle {
                anchors.centerIn: parent
                width: 44
                height: 3
                radius: 1.5
                color: Qt.alpha(Colours.palette.m3onSurfaceVariant, 0.55)
            }

            DragHandler {
                id: diagnosticsDrag

                target: null
                cursorShape: Qt.SplitVCursor
                dragThreshold: 0

                property real startHeight: 0

                onActiveChanged: {
                    if (active)
                        startHeight = root.diagnosticsHeight;
                }

                onTranslationChanged: root.diagnosticsHeight = Math.max(24, Math.min(root.height * 0.55, startHeight - translation.y))
            }
        }

        ListView {
            id: diagnosticsList

            Layout.fillWidth: true
            Layout.preferredHeight: visible ? root.diagnosticsHeight : 0
            visible: lsp.diagnostics.length > 0
            clip: true
            model: lsp.diagnostics

            delegate: Item {
                id: diagnosticItem

                required property var modelData

                width: diagnosticsList.width
                height: 24

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: Tokens.padding.medium
                    anchors.rightMargin: Tokens.padding.medium
                    spacing: Tokens.spacing.small

                    Rectangle {
                        implicitWidth: 6
                        implicitHeight: 6
                        radius: 3
                        color: root.severityColour(diagnosticItem.modelData.severity)
                    }

                    StyledText {
                        text: `${diagnosticItem.modelData.line + 1}:${diagnosticItem.modelData.character + 1}`
                        color: Colours.palette.m3onSurfaceVariant
                        font: Tokens.font.mono.small
                    }

                    StyledText {
                        Layout.fillWidth: true
                        text: diagnosticItem.modelData.message
                        elide: Text.ElideRight
                        font: Tokens.font.label.small
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor

                    onPressed: {
                        root.completionOpen = false;
                        root.contextMenuOpen = false;
                        root.diagnosticTip = "";
                    }

                    onClicked: root.jumpTo(diagnosticItem.modelData.line, diagnosticItem.modelData.character)
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: Tokens.spacing.small

            StyledText {
                text: Tr.tr("Line %1, Column %2").arg(root.caretLine + 1).arg(root.caretColumn + 1)
                color: Qt.alpha(Colours.palette.m3onSurfaceVariant, 0.6)
                font: Tokens.font.label.small
            }

            StyledText {
                visible: editor.selectionStart !== editor.selectionEnd
                text: Tr.tr("%1 selected").arg(Math.abs(editor.selectionEnd - editor.selectionStart))
                color: Qt.alpha(Colours.palette.m3onSurfaceVariant, 0.6)
                font: Tokens.font.label.small
            }

            StyledText {
                Layout.fillWidth: true
                text: Tr.tr("Ctrl+S saves · Ctrl+Z undo · Tab indents · right-click for edit actions")
                color: Qt.alpha(Colours.palette.m3onSurfaceVariant, 0.6)
                font: Tokens.font.label.small
                elide: Text.ElideRight
                horizontalAlignment: Text.AlignRight
            }
        }
    }
}
