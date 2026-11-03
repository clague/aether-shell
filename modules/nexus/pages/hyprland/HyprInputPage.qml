pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Aether.Config
import Aether.I18n
import qs.modules.nexus.common

// Keyboard, pointer and gesture settings. Everything here is a key in hypr-vars.lua; the
// input.lua and gestures.lua modules read them, so a change needs a Hyprland reload (the shell
// writes the file and asks Hyprland to reload).
PageBase {
    id: root

    title: Tr.tr("Input")
    isSubPage: true

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.extraSmall / 2

        SectionHeader {
            first: true
            text: Tr.tr("Keyboard")
        }

        HyprStringRow {
            first: true
            label: Tr.tr("Layout")
            subtext: Tr.tr("XKB layout, for example us or de")
            varKey: "kbLayout"
        }

        HyprStringRow {
            label: Tr.tr("Variant")
            subtext: Tr.tr("XKB variant, for example nodeadkeys")
            varKey: "kbVariant"
        }

        HyprStringRow {
            label: Tr.tr("Options")
            subtext: Tr.tr("XKB options, for example caps:escape")
            varKey: "kbOptions"
        }

        HyprIntRow {
            label: Tr.tr("Repeat rate")
            varKey: "repeatRate"
            from: 10
            to: 100
        }

        HyprIntRow {
            label: Tr.tr("Repeat delay")
            varKey: "repeatDelay"
            from: 100
            to: 1000
        }

        HyprBoolRow {
            last: true
            text: Tr.tr("Numlock on by default")
            varKey: "numlockByDefault"
        }

        SectionHeader {
            text: Tr.tr("Mouse")
        }

        HyprIntRow {
            first: true
            label: Tr.tr("Follow mouse")
            subtext: Tr.tr("0 is off, 1 normal, 2 loose, 3 full")
            varKey: "followMouse"
            from: 0
            to: 3
        }

        HyprSliderRow {
            label: Tr.tr("Sensitivity")
            varKey: "sensitivity"
            from: -1
            to: 1
            step: 0.05
        }

        HyprStringRow {
            label: Tr.tr("Acceleration profile")
            subtext: Tr.tr("adaptive or flat")
            varKey: "accelProfile"
        }

        HyprBoolRow {
            text: Tr.tr("Natural scroll")
            varKey: "naturalScroll"
        }

        SectionHeader {
            text: Tr.tr("Touchpad")
        }

        HyprBoolRow {
            first: true
            text: Tr.tr("Natural scroll")
            varKey: "touchpadNaturalScroll"
        }

        HyprBoolRow {
            text: Tr.tr("Disable while typing")
            varKey: "touchpadDisableTyping"
        }

        HyprFloatRow {
            label: Tr.tr("Scroll factor")
            varKey: "touchpadScrollFactor"
        }

        HyprBoolRow {
            last: true
            text: Tr.tr("Middle button emulation")
            varKey: "middleButtonEmulation"
        }

        SectionHeader {
            text: Tr.tr("Gestures")
        }

        HyprIntRow {
            first: true
            label: Tr.tr("Workspace swipe fingers")
            varKey: "workspaceSwipeFingers"
            from: 1
            to: 10
        }

        HyprIntRow {
            label: Tr.tr("Special workspace fingers")
            varKey: "gestureFingers"
            from: 1
            to: 10
        }

        HyprIntRow {
            label: Tr.tr("Sleep gesture fingers")
            varKey: "gestureFingersMore"
            from: 1
            to: 10
        }

        HyprIntRow {
            label: Tr.tr("Swipe distance")
            subtext: Tr.tr("Pixels the fingers travel for a full workspace switch")
            varKey: "workspaceSwipeDistance"
            from: 100
            to: 2000
        }

        HyprSliderRow {
            label: Tr.tr("Swipe cancel ratio")
            varKey: "workspaceSwipeCancelRatio"
            from: 0
            to: 1
            step: 0.05
        }

        HyprIntRow {
            label: Tr.tr("Swipe force speed")
            varKey: "workspaceSwipeMinSpeed"
            from: 0
            to: 20
        }

        HyprBoolRow {
            text: Tr.tr("Swipe direction lock")
            varKey: "workspaceSwipeDirLock"
        }

        HyprBoolRow {
            last: true
            text: Tr.tr("Swipe at the edge opens a new workspace")
            varKey: "workspaceSwipeCreateNew"
        }

        Item {
            Layout.preferredHeight: Tokens.padding.large
            Layout.fillWidth: true
        }
    }
}
