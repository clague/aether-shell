pragma ComponentBehavior: Bound

import QtQuick.Layouts
import Aether.Config
import Aether.I18n
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
            label: Tr.tr("Shown")
            subtext: Tr.tr("Number of workspaces displayed")
            configNode: root.targetConfig.bar.workspaces
            propertyName: "shown"
            value: root.targetConfig.bar.workspaces.shown
            from: 1
            to: 20
            stepSize: 1
            onMoved: v => {
                root.targetConfig.bar.workspaces.shown = v;
            }
        }

        ToggleRow {
            text: Tr.tr("Active indicator")
            configNode: root.targetConfig.bar.workspaces
            propertyName: "activeIndicator"
            checked: root.targetConfig.bar.workspaces.activeIndicator
            onToggled: {
                root.targetConfig.bar.workspaces.activeIndicator = checked;
            }
        }

        ToggleRow {
            text: Tr.tr("Active trail")
            configNode: root.targetConfig.bar.workspaces
            propertyName: "activeTrail"
            checked: root.targetConfig.bar.workspaces.activeTrail
            onToggled: {
                root.targetConfig.bar.workspaces.activeTrail = checked;
            }
        }

        ToggleRow {
            text: Tr.tr("Occupied background")
            configNode: root.targetConfig.bar.workspaces
            propertyName: "occupiedBg"
            checked: root.targetConfig.bar.workspaces.occupiedBg
            onToggled: {
                root.targetConfig.bar.workspaces.occupiedBg = checked;
            }
        }

        ToggleRow {
            Layout.fillWidth: true
            text: Tr.tr("Use material icons for indicators")
            configNode: root.targetConfig.bar.workspaces
            propertyName: "useIcon"
            checked: root.targetConfig.bar.workspaces.useIcon
            onToggled: {
                root.targetConfig.bar.workspaces.useIcon = checked;
            }
        }

        ToggleRow {
            Layout.fillWidth: true
            text: Tr.tr("Show windows")
            subtext: Tr.tr("Show icons of open windows on each workspace")
            configNode: root.targetConfig.bar.workspaces
            propertyName: "showWindows"
            checked: root.targetConfig.bar.workspaces.showWindows
            onToggled: {
                root.targetConfig.bar.workspaces.showWindows = checked;
            }
        }

        ToggleRow {
            text: Tr.tr("Windows on special workspaces")
            configNode: root.targetConfig.bar.workspaces
            propertyName: "showWindowsOnSpecialWorkspaces"
            checked: root.targetConfig.bar.workspaces.showWindowsOnSpecialWorkspaces
            onToggled: {
                root.targetConfig.bar.workspaces.showWindowsOnSpecialWorkspaces = checked;
            }
        }

        StepperRow {
            label: Tr.tr("Max window icons")
            configNode: root.targetConfig.bar.workspaces
            propertyName: "maxWindowIcons"
            value: root.targetConfig.bar.workspaces.maxWindowIcons
            from: 0
            to: 20
            stepSize: 1
            onMoved: v => {
                root.targetConfig.bar.workspaces.maxWindowIcons = v;
            }
        }

        ToggleRow {
            last: true
            text: Tr.tr("Per-monitor workspaces")
            subtext: Tr.tr("Show each monitor's workspaces independently")
            configNode: root.targetConfig.bar.workspaces
            propertyName: "perMonitorWorkspaces"
            checked: root.targetConfig.bar.workspaces.perMonitorWorkspaces
            onToggled: {
                root.targetConfig.bar.workspaces.perMonitorWorkspaces = checked;
            }
        }
    }
}
