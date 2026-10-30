pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import Caelestia.I18n
import qs.modules.nexus.common

// The Hyprland-side appearance variables. Look & feel applies live overrides for the most common
// ones (Density and Glass); this page edits the persisted values in hypr-vars.lua that Hyprland
// itself reads, including the details those shortcuts do not cover.
PageBase {
    id: root

    title: Tr.tr("Hyprland appearance")
    isSubPage: true

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.extraSmall / 2

        InfoRow {
            first: true
            last: true
            Layout.fillWidth: true
            icon: "info"
            label: Tr.tr("Stored in hypr-vars.lua")
            subtext: Tr.tr("Hyprland reads this file at startup; clear a row to remove its override.")
        }

        SectionHeader {
            text: Tr.tr("Blur")
        }

        HyprBoolRow {
            first: true
            text: Tr.tr("Blur enabled")
            varKey: "blurEnabled"
        }
        HyprBoolRow {
            text: Tr.tr("Blur special workspace")
            varKey: "blurSpecialWs"
        }
        HyprBoolRow {
            text: Tr.tr("Blur popups")
            varKey: "blurPopups"
        }
        HyprBoolRow {
            text: Tr.tr("Blur input methods")
            varKey: "blurInputMethods"
        }
        HyprIntRow {
            label: Tr.tr("Blur size")
            varKey: "blurSize"
            from: 1
            to: 100
        }
        HyprIntRow {
            label: Tr.tr("Blur passes")
            varKey: "blurPasses"
            from: 1
            to: 10
        }
        HyprBoolRow {
            last: true
            text: Tr.tr("Blur Xray")
            varKey: "blurXray"
        }

        SectionHeader {
            text: Tr.tr("Shadow")
        }

        HyprBoolRow {
            first: true
            text: Tr.tr("Shadow enabled")
            varKey: "shadowEnabled"
        }
        HyprIntRow {
            label: Tr.tr("Shadow range")
            varKey: "shadowRange"
            from: 1
            to: 100
        }
        HyprSliderRow {
            label: Tr.tr("Shadow render power")
            varKey: "shadowRenderPower"
            from: 1
            to: 4
            step: 1
        }
        HyprStringRow {
            last: true
            label: Tr.tr("Shadow colour")
            varKey: "shadowColour"
        }

        SectionHeader {
            text: Tr.tr("Gaps")
        }

        HyprIntRow {
            first: true
            label: Tr.tr("Workspace gaps")
            varKey: "workspaceGaps"
            from: 0
            to: 100
        }
        HyprIntRow {
            label: Tr.tr("Window gaps in")
            varKey: "windowGapsIn"
            from: 0
            to: 100
        }
        HyprIntRow {
            label: Tr.tr("Window gaps out")
            varKey: "windowGapsOut"
            from: 0
            to: 100
        }
        HyprIntRow {
            last: true
            label: Tr.tr("Single window gaps out")
            varKey: "singleWindowGapsOut"
            from: 0
            to: 100
        }

        SectionHeader {
            text: Tr.tr("Window styling")
        }

        HyprSliderRow {
            first: true
            label: Tr.tr("Window opacity")
            varKey: "windowOpacity"
            from: 0
            to: 1
            step: 0.01
        }
        HyprIntRow {
            label: Tr.tr("Window rounding")
            varKey: "windowRounding"
            from: 0
            to: 100
        }
        HyprIntRow {
            label: Tr.tr("Window border size")
            varKey: "windowBorderSize"
            from: 0
            to: 20
        }
        HyprStringRow {
            label: Tr.tr("Active window border colour")
            varKey: "activeWindowBorderColour"
        }
        HyprStringRow {
            last: true
            label: Tr.tr("Inactive window border colour")
            varKey: "inactiveWindowBorderColour"
        }

        Item {
            Layout.preferredHeight: Tokens.padding.large
            Layout.fillWidth: true
        }
    }
}
