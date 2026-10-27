pragma ComponentBehavior: Bound

import QtQuick.Layouts
import Caelestia.Config
import Caelestia.I18n
import qs.modules.nexus.common

PageBase {
    id: root

    title: Tr.tr("Workspaces")
    isSubPage: true

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.extraSmall / 2

        StepperRow {
            first: true
<<<<<<< HEAD
            label: qsTr("Shown")
            subtext: qsTr("Number of workspaces displayed")
            configNode: root.targetConfig.bar.workspaces
            propertyName: "shown"
            value: root.targetConfig.bar.workspaces.shown
=======
            // TRANSLATORS: the number of workspaces shown on the bar
            label: Tr.trCtx("Shown", "bar workspaces")
            subtext: Tr.tr("Number of workspaces displayed")
            value: Config.bar.workspaces.shown
>>>>>>> caelestia/main
            from: 1
            to: 20
            stepSize: 1
            onMoved: v => {
                root.targetConfig.bar.workspaces.shown = v;
            }
        }

        ToggleRow {
<<<<<<< HEAD
            text: qsTr("Active indicator")
            configNode: root.targetConfig.bar.workspaces
            propertyName: "activeIndicator"
            checked: root.targetConfig.bar.workspaces.activeIndicator
            onToggled: {
                root.targetConfig.bar.workspaces.activeIndicator = checked;
            }
        }

        ToggleRow {
            text: qsTr("Active trail")
            configNode: root.targetConfig.bar.workspaces
            propertyName: "activeTrail"
            checked: root.targetConfig.bar.workspaces.activeTrail
            onToggled: {
                root.targetConfig.bar.workspaces.activeTrail = checked;
            }
        }

        ToggleRow {
            text: qsTr("Occupied background")
            configNode: root.targetConfig.bar.workspaces
            propertyName: "occupiedBg"
            checked: root.targetConfig.bar.workspaces.occupiedBg
            onToggled: {
                root.targetConfig.bar.workspaces.occupiedBg = checked;
            }
        }

        ToggleRow {
            Layout.fillWidth: true
            text: qsTr("Use material icons for indicators")
            configNode: root.targetConfig.bar.workspaces
            propertyName: "useIcon"
            checked: root.targetConfig.bar.workspaces.useIcon
            onToggled: {
                root.targetConfig.bar.workspaces.useIcon = checked;
            }
        }

        ToggleRow {
            Layout.fillWidth: true
            text: qsTr("Show windows")
            subtext: qsTr("Show icons of open windows on each workspace")
            configNode: root.targetConfig.bar.workspaces
            propertyName: "showWindows"
            checked: root.targetConfig.bar.workspaces.showWindows
            onToggled: {
                root.targetConfig.bar.workspaces.showWindows = checked;
            }
        }

        ToggleRow {
            text: qsTr("Windows on special workspaces")
            configNode: root.targetConfig.bar.workspaces
            propertyName: "showWindowsOnSpecialWorkspaces"
            checked: root.targetConfig.bar.workspaces.showWindowsOnSpecialWorkspaces
            onToggled: {
                root.targetConfig.bar.workspaces.showWindowsOnSpecialWorkspaces = checked;
            }
        }

        StepperRow {
            label: qsTr("Max window icons")
            configNode: root.targetConfig.bar.workspaces
            propertyName: "maxWindowIcons"
            value: root.targetConfig.bar.workspaces.maxWindowIcons
=======
            text: Tr.trCtx("Active indicator", "bar workspaces")
            checked: Config.bar.workspaces.activeIndicator
            onToggled: GlobalConfig.bar.workspaces.activeIndicator = checked
        }

        ToggleRow {
            text: Tr.trCtx("Active trail", "bar workspaces")
            checked: Config.bar.workspaces.activeTrail
            onToggled: GlobalConfig.bar.workspaces.activeTrail = checked
        }

        ToggleRow {
            text: Tr.trCtx("Occupied background", "bar workspaces")
            checked: Config.bar.workspaces.occupiedBg
            onToggled: GlobalConfig.bar.workspaces.occupiedBg = checked
        }

        ToggleRow {
            text: Tr.trCtx("Show unoccupied", "bar workspaces")
            subtext: Tr.tr("Show workspaces that are inactive and empty")
            checked: Config.bar.workspaces.showUnoccupied
            onToggled: GlobalConfig.bar.workspaces.showUnoccupied = checked
        }

        ToggleRow {
            text: Tr.trCtx("Per monitor", "bar workspaces")
            subtext: Tr.tr("Hide workspaces not on the current monitor")
            checked: Config.bar.workspaces.perMonitor
            onToggled: GlobalConfig.bar.workspaces.perMonitor = checked
        }

        ToggleRow {
            text: Tr.trCtx("Show windows", "bar workspaces")
            subtext: Tr.tr("Show icons of open windows on each workspace")
            checked: Config.bar.workspaces.showWindows
            onToggled: GlobalConfig.bar.workspaces.showWindows = checked
        }

        ToggleRow {
            text: Tr.trCtx("Windows on special workspaces", "bar workspaces")
            checked: Config.bar.workspaces.showWindowsOnSpecialWorkspaces
            onToggled: GlobalConfig.bar.workspaces.showWindowsOnSpecialWorkspaces = checked
        }

        StepperRow {
            last: true
            // TRANSLATORS: maximum number of window icons shown per workspace
            label: Tr.trCtx("Max window icons", "bar workspaces")
            value: Config.bar.workspaces.maxWindowIcons
>>>>>>> caelestia/main
            from: 0
            to: 20
            stepSize: 1
            onMoved: v => {
                root.targetConfig.bar.workspaces.maxWindowIcons = v;
            }
        }
<<<<<<< HEAD

        ToggleRow {
            last: true
            text: qsTr("Per-monitor workspaces")
            subtext: qsTr("Show each monitor's workspaces independently")
            configNode: root.targetConfig.bar.workspaces
            propertyName: "perMonitorWorkspaces"
            checked: root.targetConfig.bar.workspaces.perMonitorWorkspaces
            onToggled: {
                root.targetConfig.bar.workspaces.perMonitorWorkspaces = checked;
            }
        }
=======
>>>>>>> caelestia/main
    }
}
