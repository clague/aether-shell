pragma ComponentBehavior: Bound

import QtQuick.Layouts
import Caelestia.Config
import qs.modules.nexus.common

PageBase {
    id: root

    title: Tr.tr("On-screen display")
    isSubPage: true

    ColumnLayout {
        anchors.horizontalCenter: parent?.horizontalCenter
        anchors.top: parent?.top
        width: root.cappedWidth
        spacing: Tokens.spacing.extraSmall / 2

        // General
        SectionHeader {
            first: true
            text: Tr.tr("General")
        }

        ToggleRow {
            first: true
            last: true
            text: Tr.tr("Enabled")
            subtext: Tr.tr("Show floating on-screen indicators when adjusting volume or brightness")
            checked: Config.osd.enabled
            onToggled: GlobalConfig.osd.enabled = checked
        }

        // Overlays
        SectionHeader {
            text: Tr.tr("Overlays")
        }

        ToggleRow {
            first: true
            text: Tr.tr("Brightness")
            subtext: Tr.tr("Show indicator when adjusting display brightness")
            disabled: !Config.osd.enabled
            checked: Config.osd.enableBrightness
            onToggled: GlobalConfig.osd.enableBrightness = checked
        }

        ToggleRow {
            last: true
            text: Tr.tr("Microphone")
            subtext: Tr.tr("Show indicator when muting or unmuting the microphone")
            disabled: !Config.osd.enabled
            checked: Config.osd.enableMicrophone
            onToggled: GlobalConfig.osd.enableMicrophone = checked
        }

        // Timing
        SectionHeader {
            text: Tr.tr("Timing")
        }

        StepperRow {
            first: true
            last: true
            label: Tr.tr("Hide delay")
            subtext: Tr.tr("Milliseconds before the indicator automatically disappears")
            disabled: !Config.osd.enabled
            value: Config.osd.hideDelay
            from: 500
            to: 6000
            stepSize: 250
            onMoved: v => GlobalConfig.osd.hideDelay = v
        }
    }
}
