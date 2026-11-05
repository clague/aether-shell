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

        HyprStringRow {
            label: Tr.tr("Solid text window classes")
            subtext: Tr.tr("Regular expression matched against window classes")
            varKey: "solidTextClasses"
        }

        RowButton {
            last: true
            icon: "restart_alt"
            text: Tr.tr("Reset glass to defaults")
            subtext: Tr.tr("Back to the look from your config")
            disabled: Glass.isDefault
            onClicked: Glass.resetAll()
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

        HyprSliderRow {
            label: Tr.tr("Rounding power")
            varKey: "windowRoundingPower"
            from: 1
            to: 10
            step: 0.5
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

        SectionHeader {
            text: Tr.tr("Window groups")
        }

        HyprStringRow {
            first: true
            label: Tr.tr("Group bar font")
            varKey: "groupbarFontFamily"
        }
        HyprIntRow {
            label: Tr.tr("Group bar font size")
            varKey: "groupbarFontSize"
            from: 6
            to: 32
        }
        HyprBoolRow {
            text: Tr.tr("Group bar gradients")
            varKey: "groupbarGradients"
        }
        HyprBoolRow {
            text: Tr.tr("Gradient on the edges only")
            varKey: "groupbarGradientRoundOnlyEdges"
        }
        HyprIntRow {
            label: Tr.tr("Gradient rounding")
            varKey: "groupbarGradientRounding"
            from: 0
            to: 20
        }
        HyprIntRow {
            label: Tr.tr("Group bar height")
            varKey: "groupbarHeight"
            from: 0
            to: 60
        }
        HyprIntRow {
            label: Tr.tr("Indicator height")
            varKey: "groupbarIndicatorHeight"
            from: 0
            to: 20
        }
        HyprIntRow {
            label: Tr.tr("Group bar gap in")
            varKey: "groupbarGapsIn"
            from: 0
            to: 20
        }
        HyprIntRow {
            label: Tr.tr("Group bar gap out")
            varKey: "groupbarGapsOut"
            from: 0
            to: 20
        }
        HyprStringRow {
            label: Tr.tr("Group bar text colour")
            varKey: "groupbarTextColour"
        }
        HyprStringRow {
            label: Tr.tr("Group bar active colour")
            varKey: "groupbarActiveColour"
        }
        HyprStringRow {
            label: Tr.tr("Group bar inactive colour")
            varKey: "groupbarInactiveColour"
        }
        HyprStringRow {
            label: Tr.tr("Group bar locked active colour")
            varKey: "groupbarLockedActiveColour"
        }
        HyprStringRow {
            last: true
            label: Tr.tr("Group bar locked inactive colour")
            varKey: "groupbarLockedInactiveColour"
        }

        SectionHeader {
            text: Tr.tr("Dimming")
        }

        HyprBoolRow {
            first: true
            text: Tr.tr("Dim inactive windows")
            subtext: Tr.tr("Fade everything except the focused window")
            varKey: "dimInactive"
        }

        HyprSliderRow {
            last: true
            label: Tr.tr("Dim strength")
            varKey: "dimStrength"
            from: 0
            to: 1
            step: 0.05
        }

        Item {
            Layout.preferredHeight: Tokens.padding.large
            Layout.fillWidth: true
        }
    }
}
