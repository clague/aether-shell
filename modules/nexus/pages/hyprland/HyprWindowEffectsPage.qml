pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Aether.Config
import Aether.I18n
import qs.services
import qs.modules.nexus.common

// Everything that changes how windows themselves are drawn: transparency, blur, shadows and
// borders. The live controls (Glass) apply through Hyprland immediately; the rows below them
// are the persisted hypr-vars.lua values Hyprland reads on start/reload.
PageBase {
    id: root

    title: Tr.tr("Window effects")
    isSubPage: true

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.extraSmall / 2

        SectionHeader {
            first: true
            text: Tr.tr("Glass")
        }

        StepperRow {
            id: opacityRow

            first: true
            label: Tr.tr("Window opacity")
            subtext: Tr.tr("How see-through app windows are (%1% is your config's value)").arg(Glass.basePercent)
            from: 50
            to: 100
            stepSize: 2
            onMoved: v => Glass.setWindowPercent(v)

            Binding {
                target: opacityRow
                property: "value"
                value: Glass.effectivePercent
            }
        }

        ToggleRow {
            id: solidRow

            text: Tr.tr("Solid text windows")
            subtext: Tr.tr("Browsers, editors, notes and document viewers stay fully opaque for easier reading")
            onToggled: Glass.setSolidText(solidRow.checked)

            Binding {
                target: solidRow
                property: "checked"
                value: Glass.solidText
            }
        }

        RowButton {
            last: true
            icon: "restart_alt"
            text: Tr.tr("Reset glass to defaults")
            subtext: Tr.tr("Back to the look from your config")
            disabled: Glass.isDefault
            onClicked: Glass.resetAll()
        }

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

        ToggleRow {
            id: overviewBlurRow

            text: Tr.tr("Blur behind the overview")
            subtext: Tr.tr("Frosted glass instead of a plain dim backdrop")
            onToggled: Glass.setOverviewBlur(overviewBlurRow.checked)

            Binding {
                target: overviewBlurRow
                property: "checked"
                value: Glass.overviewBlur
            }
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
            text: Tr.tr("Window styling")
        }

        HyprIntRow {
            first: true
            label: Tr.tr("Window rounding")
            varKey: "windowRounding"
            from: 0
            to: 100
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
