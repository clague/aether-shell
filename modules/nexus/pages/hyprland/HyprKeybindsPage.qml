pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Aether
import Aether.Blobs
import Aether.Config
import Aether.I18n
import qs.components
import qs.components.controls
import qs.services
import qs.modules.nexus.common

PageBase {
    id: root

    property var vars: ({})

    property var defaults: ({})

    readonly property string configPath: Quickshell.env("HOME") + "/.config/caelestia/hypr-vars.lua"

    readonly property string defaultsPath: Quickshell.env("HOME") + "/.config/hypr/variables.lua"

    // Two actions on one key combination is a silent failure: Hyprland fires whichever
    // bind it reaches first and reports nothing, so the only symptom is a shortcut that
    // "does nothing". This page already knows every binding, so it can say so instead.
    // Maps a var key to the other var keys sharing its combination.
    readonly property var conflicts: {
        const byCombo = {};
        const keys = new Set(Object.keys(root.defaults).concat(Object.keys(root.vars)));
        for (const key of keys) {
            const raw = root.vars[key] !== undefined ? root.vars[key] : root.defaults[key];
            // A binding may be a single string or a list of alternatives.
            for (const combo of Array.isArray(raw) ? raw : [raw]) {
                if (combo === undefined || combo === null || String(combo).length === 0)
                    continue;
                // Compare on meaning, not spelling: "CTRL + SUPER" and "super+ctrl" collide.
                const norm = String(combo).toUpperCase().split("+").map(part => part.trim()).filter(part => part.length > 0).sort().join("+");
                if (norm.length === 0)
                    continue;
                if (!byCombo[norm])
                    byCombo[norm] = [];
                byCombo[norm].push(key);
            }
        }

        const out = {};
        for (const norm in byCombo) {
            const sharing = byCombo[norm];
            if (sharing.length < 2)
                continue;
            for (const key of sharing)
                out[key] = sharing.filter(other => other !== key).map(other => root.keyLabel(other));
        }
        return out;
    }

    // Labels used both by the rows and by the duplicate-binding warning, so the two
    // cannot drift apart.
    readonly property var keyLabels: ({
            kbMoveWinToWs: Tr.tr("Move window to workspace"),
            kbMoveWinToWsGroup: Tr.tr("Move window to workspace group"),
            kbGoToWs: Tr.tr("Go to workspace"),
            kbGoToWsGroup: Tr.tr("Go to workspace group"),
            kbNextWs: Tr.tr("Next workspace"),
            kbPrevWs: Tr.tr("Previous workspace"),
            kbWindowGroupCycleNext: Tr.tr("Cycle next in group"),
            kbWindowGroupCyclePrev: Tr.tr("Cycle previous in group"),
            kbUngroup: Tr.tr("Ungroup"),
            kbToggleGroup: Tr.tr("Toggle group"),
            kbMoveWindow: Tr.tr("Move window"),
            kbResizeWindow: Tr.tr("Resize window"),
            kbWindowPip: Tr.tr("Picture-in-picture"),
            kbPinWindow: Tr.tr("Pin window"),
            kbWindowFullscreen: Tr.tr("Fullscreen"),
            kbWindowBorderedFullscreen: Tr.tr("Bordered fullscreen"),
            kbToggleWindowFloating: Tr.tr("Toggle floating"),
            kbCloseWindow: Tr.tr("Close window"),
            kbSpecialWs: Tr.tr("Special workspace toggle"),
            kbSystemMonitorWs: Tr.tr("System monitor"),
            kbMusicWs: Tr.tr("Music"),
            kbCommunicationWs: Tr.tr("Communication"),
            kbTodoWs: Tr.tr("To-do"),
            kbTerminal: Tr.tr("Terminal"),
            kbBrowser: Tr.tr("Browser"),
            kbEditor: Tr.tr("Editor"),
            kbFileExplorer: Tr.tr("File Explorer"),
            kbSession: Tr.tr("Session menu"),
            kbShowSidebar: Tr.tr("Show sidebar"),
            kbClearNotifs: Tr.tr("Clear notifications"),
            kbShowPanels: Tr.tr("Show panels"),
            kbLock: Tr.tr("Lock screen"),
            kbRestoreLock: Tr.tr("Restore lock screen")
        })

    // "kbToggleGroup" -> "toggle group" fallback for keys a user added by hand
    function prettyVarName(key: string): string {
        return key.replace(/^kb/, "").replace(/([a-z0-9])([A-Z])/g, "$1 $2").toLowerCase();
    }

    function keyLabel(key: string): string {
        return root.keyLabels[key] ?? root.prettyVarName(key);
    }

    function saveVar(key, val) {
        if (typeof val === "boolean")
            val = val ? "true" : "false";
        else if (typeof val === "string" && !val.startsWith("rgba"))
            val = '"' + val + '"';

        let content = "";
        if (CUtils.fileExists(configPath)) {
            content = CUtils.readFile(configPath);
        }
        if (!content) {
            content = "return {\n}";
        }

        let currentVars = {};
        let lines = content.split("\n");
        for (let i = 0; i < lines.length; i++) {
            let match = lines[i].match(/^\s*([a-zA-Z0-9_]+)\s*=\s*(.+?)\s*,?$/);
            if (match && match[1] !== "return" && match[1] !== "local") {
                currentVars[match[1]] = match[2];
            }
        }

        currentVars[key] = val;

        let needsScheme = false;
        for (let k in currentVars) {
            if (String(currentVars[k]).includes("scheme."))
                needsScheme = true;
        }

        let newContent = needsScheme ? 'local scheme = require("scheme.current")\n\nreturn {\n' : 'return {\n';
        let written = {};

        let schema = [
            {
                cat: "Apps",
                keys: ["terminal", "browser", "editor", "fileExplorer", "audioSettings"]
            },
            {
                cat: "Touchpad",
                keys: ["touchpadDisableTyping", "touchScrollFactor", "gestureFingers", "workspaceSwipeFingers", "gestureFingersMore"]
            },
            {
                cat: "Blur",
                keys: ["blurEnabled", "blurSpecialWs", "blurPopups", "blurInputMethods", "blurSize", "blurPasses", "blurXray"]
            },
            {
                cat: "Shadow",
                keys: ["shadowEnabled", "shadowRange", "shadowRenderPower", "shadowColour"]
            },
            {
                cat: "Gaps",
                keys: ["workspaceGaps", "windowGapsIn", "windowGapsOut", "singleWindowGapsOut"]
            },
            {
                cat: "Window styling",
                keys: ["windowOpacity", "windowRounding", "windowBorderSize", "activeWindowBorderColour", "inactiveWindowBorderColour"]
            },
            {
                cat: "Misc",
                keys: ["volumeStep", "cursorTheme", "cursorSize", "sleepGestureCmd"]
            },
            {
                cat: "Workspaces",
                keys: ["kbMoveWinToWs", "kbMoveWinToWsGroup", "kbGoToWs", "kbGoToWsGroup", "kbNextWs", "kbPrevWs"]
            },
            {
                cat: "Window Group",
                keys: ["kbWindowGroupCycleNext", "kbWindowGroupCyclePrev", "kbUngroup", "kbToggleGroup"]
            },
            {
                cat: "Window Action",
                keys: ["kbMoveWindow", "kbResizeWindow", "kbWindowPip", "kbPinWindow", "kbWindowFullscreen", "kbWindowBorderedFullscreen", "kbToggleWindowFloating", "kbCloseWindow"]
            },
            {
                cat: "Special workspaces toggles",
                keys: ["kbSpecialWs", "kbSystemMonitorWs", "kbMusicWs", "kbCommunicationWs", "kbTodoWs"]
            },
            {
                cat: "Apps (Keybinds)",
                keys: ["kbTerminal", "kbBrowser", "kbEditor", "kbFileExplorer"]
            },
            {
                cat: "Misc (Keybinds)",
                keys: ["kbSession", "kbShowSidebar", "kbClearNotifs", "kbShowPanels", "kbLock", "kbRestoreLock"]
            }
        ];

        for (let c = 0; c < schema.length; c++) {
            let cat = schema[c];
            let catHasVars = false;

            for (let k = 0; k < cat.keys.length; k++) {
                let kName = cat.keys[k];
                if (currentVars[kName] !== undefined) {
                    if (!catHasVars) {
                        newContent += "    -- " + cat.cat + "\n";
                        catHasVars = true;
                    }
                    newContent += "    " + kName.padEnd(26) + " = " + currentVars[kName] + ",\n";
                    written[kName] = true;
                }
            }
            if (catHasVars)
                newContent += "\n";
        }

        let customHasVars = false;
        for (let kName in currentVars) {
            if (!written[kName]) {
                if (!customHasVars) {
                    newContent += "    -- Custom\n";
                    customHasVars = true;
                }
                newContent += "    " + kName.padEnd(26) + " = " + currentVars[kName] + ",\n";
            }
        }

        newContent = newContent.replace(/\s+$/, "") + "\n}\n";

        try {
            CUtils.writeFile(configPath, newContent);
        } catch (e) {
            console.log("Could not write file natively yet: " + e);
            Quickshell.execDetached(["bash", "-c", "cat << 'EOF' > " + configPath + "\n" + newContent + "\nEOF"]);
        }
        loadVars();
    }

    function deleteVar(key) {
        if (!CUtils.fileExists(configPath))
            return;
        let content = CUtils.readFile(configPath);
        if (!content)
            return;

        let currentVars = {};
        let lines = content.split("\n");
        for (let i = 0; i < lines.length; i++) {
            let match = lines[i].match(/^\s*([a-zA-Z0-9_]+)\s*=\s*(.+?)\s*,?$/);
            if (match && match[1] !== "return" && match[1] !== "local") {
                currentVars[match[1]] = match[2];
            }
        }

        if (currentVars[key] === undefined)
            return;
        delete currentVars[key];

        let needsScheme = false;
        for (let k in currentVars) {
            if (String(currentVars[k]).includes("scheme."))
                needsScheme = true;
        }

        let newContent = needsScheme ? 'local scheme = require("scheme.current")\n\nreturn {\n' : 'return {\n';
        let written = {};

        let schema = [
            {
                cat: "Apps",
                keys: ["terminal", "browser", "editor", "fileExplorer", "audioSettings"]
            },
            {
                cat: "Touchpad",
                keys: ["touchpadDisableTyping", "touchScrollFactor", "gestureFingers", "workspaceSwipeFingers", "gestureFingersMore"]
            },
            {
                cat: "Blur",
                keys: ["blurEnabled", "blurSpecialWs", "blurPopups", "blurInputMethods", "blurSize", "blurPasses", "blurXray"]
            },
            {
                cat: "Shadow",
                keys: ["shadowEnabled", "shadowRange", "shadowRenderPower", "shadowColour"]
            },
            {
                cat: "Gaps",
                keys: ["workspaceGaps", "windowGapsIn", "windowGapsOut", "singleWindowGapsOut"]
            },
            {
                cat: "Window styling",
                keys: ["windowOpacity", "windowRounding", "windowBorderSize", "activeWindowBorderColour", "inactiveWindowBorderColour"]
            },
            {
                cat: "Misc",
                keys: ["volumeStep", "cursorTheme", "cursorSize", "sleepGestureCmd"]
            },
            {
                cat: "Workspaces",
                keys: ["kbMoveWinToWs", "kbMoveWinToWsGroup", "kbGoToWs", "kbGoToWsGroup", "kbNextWs", "kbPrevWs"]
            },
            {
                cat: "Window Group",
                keys: ["kbWindowGroupCycleNext", "kbWindowGroupCyclePrev", "kbUngroup", "kbToggleGroup"]
            },
            {
                cat: "Window Action",
                keys: ["kbMoveWindow", "kbResizeWindow", "kbWindowPip", "kbPinWindow", "kbWindowFullscreen", "kbWindowBorderedFullscreen", "kbToggleWindowFloating", "kbCloseWindow"]
            },
            {
                cat: "Special workspaces toggles",
                keys: ["kbSpecialWs", "kbSystemMonitorWs", "kbMusicWs", "kbCommunicationWs", "kbTodoWs"]
            },
            {
                cat: "Apps (Keybinds)",
                keys: ["kbTerminal", "kbBrowser", "kbEditor", "kbFileExplorer"]
            },
            {
                cat: "Misc (Keybinds)",
                keys: ["kbSession", "kbShowSidebar", "kbClearNotifs", "kbShowPanels", "kbLock", "kbRestoreLock"]
            }
        ];

        for (let c = 0; c < schema.length; c++) {
            let cat = schema[c];
            let catHasVars = false;

            for (let k = 0; k < cat.keys.length; k++) {
                let kName = cat.keys[k];
                if (currentVars[kName] !== undefined) {
                    if (!catHasVars) {
                        newContent += "    -- " + cat.cat + "\n";
                        catHasVars = true;
                    }
                    newContent += "    " + kName.padEnd(26) + " = " + currentVars[kName] + ",\n";
                    written[kName] = true;
                }
            }
            if (catHasVars)
                newContent += "\n";
        }

        let customHasVars = false;
        for (let kName in currentVars) {
            if (!written[kName]) {
                if (!customHasVars) {
                    newContent += "    -- Custom\n";
                    customHasVars = true;
                }
                newContent += "    " + kName.padEnd(26) + " = " + currentVars[kName] + ",\n";
            }
        }

        newContent = newContent.replace(/\s+$/, "") + "\n}\n";

        try {
            CUtils.writeFile(configPath, newContent);
        } catch (e) {
            console.log("Could not write file natively yet: " + e);
            Quickshell.execDetached(["bash", "-c", "cat << 'EOF' > " + configPath + "\n" + newContent + "\nEOF"]);
        }
        loadVars();
    }

    function loadVars() {
        let defContent = CUtils.readFile(defaultsPath);
        let dVars = {};
        if (defContent) {
            let dLines = defContent.split("\n");
            for (let i = 0; i < dLines.length; i++) {
                let line = dLines[i].trim();
                let match = line.match(/^([a-zA-Z0-9_]+)\s*=\s*(.+?)\s*,?$/);
                if (match) {
                    let key = match[1], val = match[2];
                    if (val === "true")
                        val = true;
                    else if (val === "false")
                        val = false;
                    else if (val.startsWith("\"") && val.endsWith("\""))
                        val = val.substring(1, val.length - 1);
                    else if (!isNaN(parseFloat(val)))
                        val = parseFloat(val);
                    dVars[key] = val;
                }
            }
        }
        root.defaults = dVars;

        let content = "";
        if (CUtils.fileExists(configPath)) {
            content = CUtils.readFile(configPath);
        }
        let newVars = {};
        if (content) {
            let textLines = content.split("\n");
            for (let i = 0; i < textLines.length; i++) {
                let line = textLines[i].trim();
                let match = line.match(/^([a-zA-Z0-9_]+)\s*=\s*(.+?)\s*,?$/);
                if (match) {
                    let key = match[1], val = match[2];
                    if (val === "true")
                        val = true;
                    else if (val === "false")
                        val = false;
                    else if (val.startsWith("\"") && val.endsWith("\""))
                        val = val.substring(1, val.length - 1);
                    else if (!isNaN(parseFloat(val)))
                        val = parseFloat(val);
                    newVars[key] = val;
                }
            }
        }
        root.vars = newVars;
    }

    title: Tr.tr("Keybinds")
    isSubPage: true

    Component.onCompleted: {
        if (Hypr.usingLua) {
            Quickshell.execDetached(["hyprctl", "eval", "hl.define_submap('record', function() hl.bind('XF86LaunchA', hl.dsp.submap('reset')) end)"]);
        } else {
            Hypr.extras.batchMessage(["keyword submap record", "keyword bind ,XF86LaunchA,submap,reset", "keyword submap reset"]);
        }
        loadVars();
    }

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.extraSmall / 2

        SectionHeader {
            first: true
            text: Tr.tr("Workspaces")
        }

        KeybindRow {
            first: true
            label: root.keyLabel("kbMoveWinToWs")
            varKey: "kbMoveWinToWs"
        }
        KeybindRow {
            label: root.keyLabel("kbMoveWinToWsGroup")
            varKey: "kbMoveWinToWsGroup"
        }
        KeybindRow {
            label: root.keyLabel("kbGoToWs")
            varKey: "kbGoToWs"
        }
        KeybindRow {
            label: root.keyLabel("kbGoToWsGroup")
            varKey: "kbGoToWsGroup"
        }
        KeybindRow {
            label: root.keyLabel("kbNextWs")
            varKey: "kbNextWs"
        }
        KeybindRow {
            last: true
            label: root.keyLabel("kbPrevWs")
            varKey: "kbPrevWs"
        }

        SectionHeader {
            text: Tr.tr("Window Group")
        }

        KeybindRow {
            first: true
            label: root.keyLabel("kbWindowGroupCycleNext")
            varKey: "kbWindowGroupCycleNext"
        }
        KeybindRow {
            label: root.keyLabel("kbWindowGroupCyclePrev")
            varKey: "kbWindowGroupCyclePrev"
        }
        KeybindRow {
            label: root.keyLabel("kbUngroup")
            varKey: "kbUngroup"
        }
        KeybindRow {
            last: true
            label: root.keyLabel("kbToggleGroup")
            varKey: "kbToggleGroup"
        }

        SectionHeader {
            text: Tr.tr("Window Action")
        }

        KeybindRow {
            first: true
            label: root.keyLabel("kbMoveWindow")
            varKey: "kbMoveWindow"
        }
        KeybindRow {
            label: root.keyLabel("kbResizeWindow")
            varKey: "kbResizeWindow"
        }
        KeybindRow {
            label: root.keyLabel("kbWindowPip")
            varKey: "kbWindowPip"
        }
        KeybindRow {
            label: root.keyLabel("kbPinWindow")
            varKey: "kbPinWindow"
        }
        KeybindRow {
            label: root.keyLabel("kbWindowFullscreen")
            varKey: "kbWindowFullscreen"
        }
        KeybindRow {
            label: root.keyLabel("kbWindowBorderedFullscreen")
            varKey: "kbWindowBorderedFullscreen"
        }
        KeybindRow {
            label: root.keyLabel("kbToggleWindowFloating")
            varKey: "kbToggleWindowFloating"
        }
        KeybindRow {
            last: true
            label: root.keyLabel("kbCloseWindow")
            varKey: "kbCloseWindow"
        }

        SectionHeader {
            text: Tr.tr("Special Workspaces")
        }

        KeybindRow {
            first: true
            label: root.keyLabel("kbSpecialWs")
            varKey: "kbSpecialWs"
        }
        KeybindRow {
            label: root.keyLabel("kbSystemMonitorWs")
            varKey: "kbSystemMonitorWs"
        }
        KeybindRow {
            label: root.keyLabel("kbMusicWs")
            varKey: "kbMusicWs"
        }
        KeybindRow {
            label: root.keyLabel("kbCommunicationWs")
            varKey: "kbCommunicationWs"
        }
        KeybindRow {
            last: true
            label: root.keyLabel("kbTodoWs")
            varKey: "kbTodoWs"
        }

        SectionHeader {
            text: Tr.tr("Apps")
        }

        KeybindRow {
            first: true
            label: root.keyLabel("kbTerminal")
            varKey: "kbTerminal"
        }
        KeybindRow {
            label: root.keyLabel("kbBrowser")
            varKey: "kbBrowser"
        }
        KeybindRow {
            label: root.keyLabel("kbEditor")
            varKey: "kbEditor"
        }
        KeybindRow {
            last: true
            label: root.keyLabel("kbFileExplorer")
            varKey: "kbFileExplorer"
        }

        SectionHeader {
            text: Tr.tr("Misc")
        }

        KeybindRow {
            first: true
            label: root.keyLabel("kbSession")
            varKey: "kbSession"
        }
        KeybindRow {
            label: root.keyLabel("kbShowSidebar")
            varKey: "kbShowSidebar"
        }
        KeybindRow {
            label: root.keyLabel("kbClearNotifs")
            varKey: "kbClearNotifs"
        }
        KeybindRow {
            label: root.keyLabel("kbShowPanels")
            varKey: "kbShowPanels"
        }
        KeybindRow {
            label: root.keyLabel("kbLock")
            varKey: "kbLock"
        }
        KeybindRow {
            last: true
            label: root.keyLabel("kbRestoreLock")
            varKey: "kbRestoreLock"
        }

        Item {
            Layout.preferredHeight: Tokens.padding.large
            Layout.fillWidth: true
        }
    }

    component KeybindRow: ConnectedRect {
        id: kroot

        property string label
        property string varKey
        property bool recording: false

        Layout.fillWidth: true
        implicitHeight: contentRow.implicitHeight + contentRow.anchors.margins * 2

        StateLayer {
            id: stateLayer
            anchors.fill: parent
            onClicked: {
                kroot.recording = !kroot.recording;
                if (kroot.recording) {
                    focusItem.forceActiveFocus();
                    if (Hypr.usingLua) {
                        Quickshell.execDetached(["hyprctl", "eval", "hl.define_submap('record', function() hl.bind('XF86LaunchA', hl.dsp.submap('reset')) end); hl.dispatch(hl.dsp.submap('record'))"]);
                    } else {
                        Hypr.extras.batchMessage(["keyword submap record", "keyword bind ,XF86LaunchA,submap,reset", "keyword submap reset"]);
                        Hypr.dispatch("submap record");
                    }
                } else {
                    Hypr.dispatch(Hypr.usingLua ? 'hl.dsp.submap("reset")' : "submap reset");
                }
            }
        }

        RowLayout {
            id: contentRow
            anchors.fill: parent
            anchors.margins: Tokens.padding.medium
            anchors.leftMargin: Tokens.padding.largeIncreased
            anchors.rightMargin: Tokens.padding.largeIncreased
            spacing: Tokens.spacing.medium

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0

                RowLayout {
                    Layout.fillWidth: true
                    spacing: Tokens.spacing.small

                    StyledText {
                        text: kroot.label
                        font: Tokens.font.body.small
                        elide: Text.ElideRight
                    }

                    IconButton {
                        icon: "delete"
                        type: IconButton.Text
                        font: Tokens.font.icon.small
                        visible: root.vars[kroot.varKey] !== undefined
                        onClicked: root.deleteVar(kroot.varKey)
                    }

                    Item {
                        Layout.fillWidth: true
                    }
                }

                StyledText {
                    readonly property var clash: root.conflicts[kroot.varKey] ?? []
                    readonly property string binding: root.vars[kroot.varKey] !== undefined ? String(root.vars[kroot.varKey]) : (root.defaults[kroot.varKey] !== undefined ? String(root.defaults[kroot.varKey]) : Tr.tr("Unbound"))

                    text: kroot.recording ? Tr.tr("Recording…") : (clash.length > 0 ? Tr.tr("%1 — also bound to %2").arg(binding).arg(clash.join(", ")) : binding)
                    color: !kroot.recording && clash.length > 0 ? Colours.palette.m3error : Colours.palette.m3outline
                    font: Tokens.font.label.small
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                }
            }

            Item {
                id: recordBtn

                implicitWidth: btn.implicitWidth * 0.9
                implicitHeight: btn.implicitHeight * 0.9

                BlobGroup {
                    id: blobGroup
                    color: kroot.recording || stateLayer.containsMouse ? Colours.palette.m3secondaryContainer : Colours.palette.m3surfaceContainerHighest
                    smoothing: kroot.Tokens.rounding.medium
                    cornerFill: false

                    Behavior on color {
                        CAnim {}
                    }
                }

                BlobRect {
                    id: btnRect
                    anchors.fill: parent
                    anchors.margins: (stateLayer.containsMouse ? -Tokens.padding.extraSmall : 0) + (kroot.recording ? -Tokens.padding.extraSmall : 0)
                    group: blobGroup
                    radius: kroot.recording ? Tokens.rounding.large : Tokens.rounding.medium

                    Behavior on anchors.margins {
                        Anim {}
                    }

                    Behavior on radius {
                        Anim {
                            type: Anim.DefaultEffects
                        }
                    }
                }

                Item {
                    id: btn
                    anchors.centerIn: parent
                    implicitWidth: implicitHeight
                    implicitHeight: icon.implicitHeight + Tokens.padding.extraSmall * 2

                    MaterialIcon {
                        id: icon
                        anchors.centerIn: parent
                        text: kroot.recording ? "stop_circle" : "screen_record"
                        color: kroot.recording || stateLayer.containsMouse ? Colours.palette.m3onSecondaryContainer : Colours.palette.m3onSurfaceVariant
                        fontStyle: Tokens.font.icon.medium
                    }
                }
            }
        }

        Item {
            id: focusItem

            property bool modifierOnly: false
            property var lastMods: []

            focus: kroot.recording

            Keys.onPressed: event => {
                if (!kroot.recording)
                    return;
                let k = event.key;
                if (k === Qt.Key_Escape) {
                    kroot.recording = false;
                    Hypr.dispatch(Hypr.usingLua ? 'hl.dsp.submap("reset")' : "submap reset");
                    event.accepted = true;
                    return;
                }

                let mods = [];
                if (event.modifiers & Qt.ControlModifier)
                    mods.push("CTRL");
                if (event.modifiers & Qt.ShiftModifier)
                    mods.push("SHIFT");
                if (event.modifiers & Qt.AltModifier)
                    mods.push("ALT");
                if (event.modifiers & Qt.MetaModifier)
                    mods.push("SUPER");

                let keyStr = "";
                if (k >= Qt.Key_A && k <= Qt.Key_Z) {
                    keyStr = String.fromCharCode(k);
                } else if (k >= Qt.Key_0 && k <= Qt.Key_9) {
                    keyStr = String.fromCharCode(k);
                } else {
                    let map = {
                        [Qt.Key_Return]: "Return",
                        [Qt.Key_Enter]: "Return",
                        [Qt.Key_Space]: "Space",
                        [Qt.Key_Tab]: "Tab",
                        [Qt.Key_Backtab]: "Tab",
                        [Qt.Key_Backspace]: "Backspace",
                        [Qt.Key_Minus]: "minus",
                        [Qt.Key_Equal]: "equal",
                        [Qt.Key_BracketLeft]: "bracketleft",
                        [Qt.Key_BracketRight]: "bracketright",
                        [Qt.Key_Semicolon]: "semicolon",
                        [Qt.Key_Apostrophe]: "apostrophe",
                        // qmllint disable missing-property
                        [Qt.Key_Grave]: "grave",
                        // qmllint enable missing-property
                        [Qt.Key_Slash]: "slash",
                        [Qt.Key_Period]: "period",
                        [Qt.Key_Backslash]: "backslash",
                        [Qt.Key_Comma]: "comma",
                        [Qt.Key_Right]: "Right",
                        [Qt.Key_Left]: "Left",
                        [Qt.Key_Up]: "Up",
                        [Qt.Key_Down]: "Down",
                        [Qt.Key_Delete]: "Delete"
                    };
                    if (map[k] !== undefined)
                        keyStr = map[k];
                    else
                        keyStr = event.text.toUpperCase();
                }

                let isModKey = (k === Qt.Key_Control || k === Qt.Key_Shift || k === Qt.Key_Alt || k === Qt.Key_Meta || k === Qt.Key_Super_L || k === Qt.Key_Super_R);

                if (keyStr !== "" && !isModKey) {
                    modifierOnly = false;
                    mods.push(keyStr);
                    let finalBind = mods.join(" + ");
                    root.saveVar(kroot.varKey, finalBind);
                    kroot.recording = false;
                    Hypr.dispatch(Hypr.usingLua ? 'hl.dsp.submap("reset")' : "submap reset");
                    event.accepted = true;
                } else if (isModKey) {
                    modifierOnly = true;
                    let modStr = "";
                    if (k === Qt.Key_Control)
                        modStr = "CTRL";
                    else if (k === Qt.Key_Shift)
                        modStr = "SHIFT";
                    else if (k === Qt.Key_Alt)
                        modStr = "ALT";
                    else if (k === Qt.Key_Meta || k === Qt.Key_Super_L || k === Qt.Key_Super_R)
                        modStr = "SUPER";

                    if (!mods.includes(modStr) && modStr !== "")
                        mods.push(modStr);
                    lastMods = mods;
                    event.accepted = true;
                }
            }

            Keys.onReleased: event => {
                if (!kroot.recording)
                    return;
                let k = event.key;
                let isModKey = (k === Qt.Key_Control || k === Qt.Key_Shift || k === Qt.Key_Alt || k === Qt.Key_Meta || k === Qt.Key_Super_L || k === Qt.Key_Super_R);

                if (isModKey && modifierOnly && lastMods.length > 0) {
                    let finalBind = lastMods.join(" + ");
                    root.saveVar(kroot.varKey, finalBind);
                    kroot.recording = false;
                    Hypr.dispatch(Hypr.usingLua ? 'hl.dsp.submap("reset")' : "submap reset");
                    event.accepted = true;
                }
            }
        }
    }
}
