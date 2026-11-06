pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Aether.Config
import Aether.I18n
import qs.modules.nexus.common

PageBase {
    id: root

    readonly property bool custom: !GlobalConfig.aether.windowFrame.followWm

    title: Tr.tr("Screenshots")

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.extraSmall / 2

        SectionHeader {
            first: true
            text: Tr.tr("Window frame")
        }

        ToggleRow {
            first: true
            last: true
            text: Tr.tr("Follow the window manager")
            subtext: Tr.tr("Use Hyprland's rounding, border and shadow values")
            configNode: GlobalConfig.aether.windowFrame
            propertyName: "followWm"
            checked: GlobalConfig.aether.windowFrame.followWm
            onToggled: GlobalConfig.aether.windowFrame.followWm = checked
        }

        SectionHeader {
            visible: root.custom
            text: Tr.tr("Custom frame")
        }

        StepperRow {
            visible: root.custom
            first: true
            label: Tr.tr("Rounding")
            subtext: Tr.tr("Corner radius in pixels")
            configNode: GlobalConfig.aether.windowFrame
            propertyName: "rounding"
            value: GlobalConfig.aether.windowFrame.rounding
            from: 0
            to: 40
            stepSize: 1
            onMoved: v => GlobalConfig.aether.windowFrame.rounding = v
        }

        StepperRow {
            visible: root.custom
            label: Tr.tr("Border width")
            subtext: Tr.tr("Border width in pixels; 0 disables it")
            configNode: GlobalConfig.aether.windowFrame
            propertyName: "borderSize"
            value: GlobalConfig.aether.windowFrame.borderSize
            from: 0
            to: 20
            stepSize: 1
            onMoved: v => GlobalConfig.aether.windowFrame.borderSize = v
        }

        TextFieldRow {
            visible: root.custom
            last: !GlobalConfig.aether.windowFrame.shadowEnabled
            label: Tr.tr("Border colour")
            subtext: Tr.tr("Hex or rgba() colour")
            value: GlobalConfig.aether.windowFrame.borderColor
            placeholderText: "rgba(0, 0, 0, 0.22)"
            onEditingFinished: value => {
                GlobalConfig.aether.windowFrame.borderColor = value;
            }
        }

        ToggleRow {
            visible: root.custom
            text: Tr.tr("Shadow")
            subtext: Tr.tr("Draw a soft shadow behind the window")
            configNode: GlobalConfig.aether.windowFrame
            propertyName: "shadowEnabled"
            checked: GlobalConfig.aether.windowFrame.shadowEnabled
            onToggled: GlobalConfig.aether.windowFrame.shadowEnabled = checked
        }

        StepperRow {
            visible: root.custom && GlobalConfig.aether.windowFrame.shadowEnabled
            label: Tr.tr("Shadow range")
            subtext: Tr.tr("Shadow blur range in pixels")
            configNode: GlobalConfig.aether.windowFrame
            propertyName: "shadowRange"
            value: GlobalConfig.aether.windowFrame.shadowRange
            from: 0
            to: 100
            stepSize: 1
            onMoved: v => GlobalConfig.aether.windowFrame.shadowRange = v
        }

        StepperRow {
            visible: root.custom && GlobalConfig.aether.windowFrame.shadowEnabled
            label: Tr.tr("Shadow power")
            subtext: Tr.tr("Hyprland's render power, 1 (soft) to 4 (crisp)")
            configNode: GlobalConfig.aether.windowFrame
            propertyName: "shadowPower"
            value: GlobalConfig.aether.windowFrame.shadowPower
            from: 1
            to: 4
            stepSize: 1
            onMoved: v => GlobalConfig.aether.windowFrame.shadowPower = v
        }

        StepperRow {
            visible: root.custom && GlobalConfig.aether.windowFrame.shadowEnabled
            label: Tr.tr("Horizontal offset")
            subtext: Tr.tr("Shadow offset in pixels")
            configNode: GlobalConfig.aether.windowFrame
            propertyName: "shadowOffsetX"
            value: GlobalConfig.aether.windowFrame.shadowOffsetX
            from: -50
            to: 50
            stepSize: 1
            onMoved: v => GlobalConfig.aether.windowFrame.shadowOffsetX = v
        }

        StepperRow {
            visible: root.custom && GlobalConfig.aether.windowFrame.shadowEnabled
            label: Tr.tr("Vertical offset")
            subtext: Tr.tr("Shadow offset in pixels")
            configNode: GlobalConfig.aether.windowFrame
            propertyName: "shadowOffsetY"
            value: GlobalConfig.aether.windowFrame.shadowOffsetY
            from: -50
            to: 50
            stepSize: 1
            onMoved: v => GlobalConfig.aether.windowFrame.shadowOffsetY = v
        }

        TextFieldRow {
            visible: root.custom && GlobalConfig.aether.windowFrame.shadowEnabled
            last: true
            label: Tr.tr("Shadow colour")
            subtext: Tr.tr("Hex or rgba() colour")
            value: GlobalConfig.aether.windowFrame.shadowColor
            placeholderText: "rgba(0, 0, 0, 0.35)"
            onEditingFinished: value => {
                GlobalConfig.aether.windowFrame.shadowColor = value;
            }
        }
    }
}
