pragma ComponentBehavior: Bound

import QtQuick.Layouts
import Caelestia.Config
import qs.modules.nexus.common

PageBase {
    id: root

    title: Tr.tr("Desktop & background")
    isSubPage: true

    ColumnLayout {
        anchors.horizontalCenter: parent?.horizontalCenter
        anchors.top: parent?.top
        width: root.cappedWidth
        spacing: Tokens.spacing.extraSmall / 2

        // Desktop clock
        SectionHeader {
            first: true
            text: Tr.tr("Desktop clock")
        }

        ToggleRow {
            first: true
            last: true
            text: Tr.tr("Desktop clock")
            subtext: Tr.tr("Display clock widget directly on the desktop wallpaper")
            checked: Config.background.desktopClock.enabled
            onToggled: GlobalConfig.background.desktopClock.enabled = checked
        }

        // Background audio visualiser
        SectionHeader {
            text: Tr.tr("Background audio visualiser")
        }

        ToggleRow {
            first: true
            text: Tr.tr("Enabled")
            subtext: Tr.tr("Render live audio visualiser bars on the background")
            checked: Config.background.visualiser.enabled
            onToggled: GlobalConfig.background.visualiser.enabled = checked
        }

        ToggleRow {
            text: Tr.tr("Auto-hide")
            subtext: Tr.tr("Automatically hide visualiser when no audio is playing")
            disabled: !Config.background.visualiser.enabled
            checked: Config.background.visualiser.autoHide
            onToggled: GlobalConfig.background.visualiser.autoHide = checked
        }

        ToggleRow {
            text: Tr.tr("Blur effect")
            subtext: Tr.tr("Apply soft blur to background visualiser bars")
            disabled: !Config.background.visualiser.enabled
            checked: Config.background.visualiser.blur
            onToggled: GlobalConfig.background.visualiser.blur = checked
        }

        StepperRow {
            label: Tr.tr("Bar rounding")
            subtext: Tr.tr("Corner rounding multiplier for visualiser bars")
            disabled: !Config.background.visualiser.enabled
            value: Config.background.visualiser.rounding
            from: 0
            to: 5
            stepSize: 0.5
            onMoved: v => GlobalConfig.background.visualiser.rounding = v
        }

        StepperRow {
            last: true
            label: Tr.tr("Bar spacing")
            subtext: Tr.tr("Spacing multiplier between visualiser bars")
            disabled: !Config.background.visualiser.enabled
            value: Config.background.visualiser.spacing
            from: 0.5
            to: 5
            stepSize: 0.5
            onMoved: v => GlobalConfig.background.visualiser.spacing = v
        }

        // Borders and rounding
        SectionHeader {
            text: Tr.tr("Borders & Rounding")
        }

        StepperRow {
            first: true
            label: Tr.tr("Border thickness")
            subtext: Tr.tr("Global border thickness (pixels)")
            value: Config.border.thickness
            from: 0
            to: 20
            stepSize: 1
            onMoved: v => GlobalConfig.border.thickness = v
        }

        StepperRow {
            last: true
            label: Tr.tr("Corner rounding")
            subtext: Tr.tr("Global corner rounding radius (pixels)")
            value: Config.border.rounding
            from: 0
            to: 40
            stepSize: 1
            onMoved: v => GlobalConfig.border.rounding = v
        }
    }
}
