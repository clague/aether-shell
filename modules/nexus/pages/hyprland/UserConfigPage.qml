pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
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
    readonly property real lineHeight: Math.max(1, editor.cursorRectangle.height)
    readonly property string lineNumbers: {
        let out = "";
        for (let i = 1; i <= editor.lineCount; i++)
            out += (i === 1 ? "" : "\n") + i;
        return out;
    }

    property string savedText: ""
    property string notice: ""
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
        const trimmed = line.trimEnd();
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
                    root.completionIndex = 0;
                    root.completionOpen = true;
                    root.updateCompletionPosition();
                    Qt.callLater(root.updateCompletionPosition);
                } else {
                    root.completionOpen = false;
                }
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

                Text {
                    x: 10
                    y: editor.y - flick.contentY
                    text: root.lineNumbers
                    color: Qt.alpha(Colours.palette.m3onSurfaceVariant, 0.7)
                    font: editor.font
                    lineHeightMode: Text.FixedHeight
                    lineHeight: root.lineHeight
                }

                Repeater {
                    model: lsp.diagnostics

                    Rectangle {
                        id: gutterMarker

                        required property var modelData

                        x: 4
                        y: editor.y + gutterMarker.modelData.line * root.lineHeight + (root.lineHeight - 5) / 2 - flick.contentY
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
                    height: root.lineHeight
                    color: Qt.alpha(Colours.palette.m3primary, 0.05)
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
                        if (lsp.status === "ready")
                            syncTimer.restart();
                        if (!root.suppressCompletion) {
                            if (root.shouldAutoComplete())
                                completionTimer.restart();
                            else if (root.completionOpen)
                                root.completionOpen = false;
                        }
                    }

                    onCursorPositionChanged: {
                        if (root.completionOpen)
                            root.updateCompletionPosition();
                        root.ensureCursorVisible();
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
        }

        ListView {
            id: diagnosticsList

            Layout.fillWidth: true
            Layout.preferredHeight: visible ? Math.min(96, contentHeight) : 0
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
