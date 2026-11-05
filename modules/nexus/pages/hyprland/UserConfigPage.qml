pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
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
    property real lineHeight: 1
    property var squiggles: []

    property string savedText: ""
    property string notice: ""
    property string diagnosticTip: ""
    property real diagnosticTipAnchorX: 0
    property real diagnosticTipAnchorY: 0
    property real diagnosticsHeight: 96
    property bool completionOpen: false
    property bool suppressCompletion: false
    property int completionIndex: 0
    property real completionX: 0
    property real completionY: 0
    readonly property real completionHeight: Math.min(220, Math.max(24, completionList.contentHeight + 8))

    function save(): bool {
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

        root.completionX = Math.max(8, Math.min(gutter.width + editor.x + rect.x - flick.contentX, Math.max(8, flick.width - 340)));
        root.completionY = below + height > flick.height && above >= 0 ? above : Math.max(0, Math.min(below, flick.height - height));
    }

    // Keeps the caret inside the viewport when it moves by keyboard or after a jump (Ctrl+End,
    // clicking a diagnostic, accepting a completion...). The Flickable does not follow the editor
    // on its own.
    function ensureCursorVisible(): void {
        if (flick.height <= 0 || editor.cursorRectangle.height <= 0)
            return;

        const margin = root.lineHeight * 2;
        const rect = editor.cursorRectangle;
        const top = editor.y + rect.y;
        const bottom = top + rect.height;

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
    }

    function offsetAt(line: int, character: int): int {
        const lines = editor.text.split("\n");
        let offset = 0;
        for (let i = 0; i < line && i < lines.length; i++)
            offset += lines[i].length + 1;
        return offset + Math.min(character, (lines[line] ?? "").length);
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
        const lines = editor.text.split("\n");
        let offset = 0;
        for (let i = 0; i < line && i < lines.length; i++)
            offset += lines[i].length + 1;
        editor.cursorPosition = offset + Math.min(character, (lines[line] ?? "").length);
        editor.forceActiveFocus();
        root.ensureCursorVisible();
    }

    function recomputeLineRects(): void {
        const text = editor.text;
        const rects = [];
        let offset = 0;
        while (true) {
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
        root.squiggles = result;
    }

    function lineCharacterAt(position: int): var {
        const before = editor.text.slice(0, position);
        return {
            line: before.split("\n").length - 1,
            character: position - before.lastIndexOf("\n") - 1
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
                anchors.right: parent.right
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

                StyledScrollBar {
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    flickable: flick
                    orientation: Qt.Vertical
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
                    height: contentHeight

                    color: Colours.palette.m3onSurface
                    selectionColor: Qt.alpha(Colours.palette.m3primary, 0.35)
                    selectedTextColor: Colours.palette.m3onSurface
                    font: Tokens.font.mono.medium
                    wrapMode: TextEdit.NoWrap
                    selectByMouse: true
                    focus: true

                    onTextChanged: {
                        root.diagnosticTip = "";
                        root.recomputeLineRects();
                        root.rebuildSquiggles();
                        Qt.callLater(root.recomputeLineRects);
                        Qt.callLater(root.rebuildSquiggles);
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
                        if (root.completionOpen)
                            root.updateCompletionPosition();
                        root.ensureCursorVisible();
                        // contentHeight can lag one frame behind a new line; scroll again once it
                        // has grown, otherwise the last line stays half-clipped at the bottom.
                        Qt.callLater(root.ensureCursorVisible);
                    }

                    Keys.onPressed: event => {
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

            StyledRect {
                id: completionPopup

                x: root.completionX
                y: root.completionY
                width: 340
                height: root.completionHeight
                visible: root.completionOpen && lsp.completions.length > 0
                z: 10
                radius: Tokens.rounding.medium
                color: Colours.palette.m3surfaceContainerHigh

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
                        width: 6
                        height: 6
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
                    onClicked: root.jumpTo(diagnosticItem.modelData.line, diagnosticItem.modelData.character)
                }
            }
        }

        StyledText {
            Layout.fillWidth: true
            text: Tr.tr("Ctrl+S saves · completion opens as you type · Tab indents · the language server shows problems")
            color: Qt.alpha(Colours.palette.m3onSurfaceVariant, 0.6)
            font: Tokens.font.label.small
            elide: Text.ElideRight
        }
    }
}
