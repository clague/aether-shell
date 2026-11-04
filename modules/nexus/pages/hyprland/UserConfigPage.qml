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
    property int completionIndex: 0
    property real completionX: 0
    property real completionY: 0

    function save(): void {
        if (!CUtils.writeFile(root.filePath, editor.text)) {
            root.notice = Tr.tr("Could not write the file");
            return;
        }
        root.savedText = editor.text;
        root.notice = Tr.tr("Saved");
        noticeTimer.restart();
    }

    function revert(): void {
        editor.text = root.savedText;
        editor.cursorPosition = 0;
        root.completionOpen = false;
    }

    function insertNewline(): void {
        const position = editor.cursorPosition;
        const lineStart = editor.text.lastIndexOf("\n", position - 1) + 1;
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

    function dedentLine(): void {
        const position = editor.cursorPosition;
        const lineStart = editor.text.lastIndexOf("\n", position - 1) + 1;
        const line = editor.text.slice(lineStart, position);
        if (line.startsWith("    "))
            editor.remove(lineStart, lineStart + 4);
        else if (line.startsWith("\t"))
            editor.remove(lineStart, lineStart + 1);
    }

    function requestCompletion(): void {
        const before = editor.text.slice(0, editor.cursorPosition);
        const line = before.split("\n").length - 1;
        const character = before.length - before.lastIndexOf("\n") - 1;
        lsp.requestCompletion(line, character);
    }

    function updateCompletionPosition(): void {
        const rect = editor.cursorRectangle;
        root.completionX = Math.max(8, Math.min(gutter.width + editor.x + rect.x - flick.contentX, flick.width - 340));
        root.completionY = editor.y + rect.y + rect.height - flick.contentY;
    }

    function acceptCompletion(): void {
        const item = lsp.completions[root.completionIndex];
        root.completionOpen = false;
        if (!item)
            return;

        let start = editor.cursorPosition;
        while (start > 0 && /[A-Za-z0-9_.:]/.test(editor.text[start - 1]))
            start--;

        editor.remove(start, editor.cursorPosition);
        editor.insert(start, item.insert);
    }

    function jumpTo(line: int, character: int): void {
        const lines = editor.text.split("\n");
        let offset = 0;
        for (let i = 0; i < line && i < lines.length; i++)
            offset += lines[i].length + 1;
        editor.cursorPosition = offset + Math.min(character, (lines[line] ?? "").length);
        editor.forceActiveFocus();
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

            interval: 300
            onTriggered: root.requestCompletion()
        }

        Process {
            id: reloadProc

            command: ["hyprctl", "reload"]
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
                onClicked: reloadProc.running = true
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
                        if (root.completionOpen)
                            completionTimer.restart();
                    }

                    onCursorPositionChanged: {
                        if (root.completionOpen)
                            root.updateCompletionPosition();
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
                        if (pairs[event.text] !== undefined) {
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
                            editor.insert(editor.cursorPosition, "    ");
                            event.accepted = true;
                            return;
                        }
                        if (event.key === Qt.Key_Backtab) {
                            root.dedentLine();
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
                height: Math.min(220, completionList.contentHeight + 8)
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
            text: Tr.tr("Ctrl+S saves · Ctrl+Space completes · Tab indents · the language server shows problems")
            color: Qt.alpha(Colours.palette.m3onSurfaceVariant, 0.6)
            font: Tokens.font.label.small
            elide: Text.ElideRight
        }
    }
}
