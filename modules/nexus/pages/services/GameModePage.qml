import QtQuick
import QtQuick.Layouts
import Aether.Config
import Aether.I18n
import qs.modules.nexus.common

PageBase {
    id: root

    title: Tr.tr("Game mode")
    isSubPage: true

    ColumnLayout {
        id: layout

        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.extraSmall / 2

        SectionHeader {
            first: true
            text: Tr.tr("Auto-enable rules")
        }

        ToggleRow {
            first: true
            text: Tr.tr("Enable automatically")
            subtext: Tr.tr("Turn on game mode when a target window is focused or running")
            configNode: root.targetConfig.utilities.gameMode
            propertyName: "autoEnable"
            checked: root.targetConfig.utilities.gameMode.autoEnable
            onToggled: {
                root.targetConfig.utilities.gameMode.autoEnable = checked;
            }
        }

        NavRow {
            last: true
            icon: "ads_click"
            text: Tr.tr("Target windows")
            subtext: Tr.tr("Add or remove auto-enable targets")
            onClicked: root.nState.openSubPage(3)
        }

        SectionHeader {
            text: Tr.tr("Hyprland overrides")
        }

        ToggleRow {
            first: true
            text: Tr.tr("Disable animations")
            configNode: root.targetConfig.utilities.gameMode
            propertyName: "disableHyprlandAnimations"
            checked: root.targetConfig.utilities.gameMode.disableHyprlandAnimations
            onToggled: {
                root.targetConfig.utilities.gameMode.disableHyprlandAnimations = checked;
            }
        }
        ToggleRow {
            text: Tr.tr("Disable blur")
            configNode: root.targetConfig.utilities.gameMode
            propertyName: "disableHyprlandBlur"
            checked: root.targetConfig.utilities.gameMode.disableHyprlandBlur
            onToggled: {
                root.targetConfig.utilities.gameMode.disableHyprlandBlur = checked;
            }
        }
        ToggleRow {
            text: Tr.tr("Disable gaps and rounding")
            configNode: root.targetConfig.utilities.gameMode
            propertyName: "disableHyprlandGaps"
            checked: root.targetConfig.utilities.gameMode.disableHyprlandGaps
            onToggled: {
                root.targetConfig.utilities.gameMode.disableHyprlandGaps = checked;
            }
        }
        ToggleRow {
            text: Tr.tr("Disable shadows")
            configNode: root.targetConfig.utilities.gameMode
            propertyName: "disableHyprlandShadows"
            checked: root.targetConfig.utilities.gameMode.disableHyprlandShadows
            onToggled: {
                root.targetConfig.utilities.gameMode.disableHyprlandShadows = checked;
            }
        }
        ToggleRow {
            text: Tr.tr("Disable window transparency")
            last: true
            configNode: root.targetConfig.utilities.gameMode
            propertyName: "disableWindowTransparency"
            checked: root.targetConfig.utilities.gameMode.disableWindowTransparency
            onToggled: {
                root.targetConfig.utilities.gameMode.disableWindowTransparency = checked;
            }
        }

        SectionHeader {
            text: Tr.tr("MiDnight feature overrides")
        }

        ToggleRow {
            first: true
            text: Tr.tr("Disable shell transparency")
            configNode: root.targetConfig.utilities.gameMode
            propertyName: "disableShellTransparency"
            checked: root.targetConfig.utilities.gameMode.disableShellTransparency
            onToggled: {
                root.targetConfig.utilities.gameMode.disableShellTransparency = checked;
            }
        }
        ToggleRow {
            text: Tr.tr("Disable toast notifications transparency")
            configNode: root.targetConfig.utilities.gameMode
            propertyName: "disableToastTransparency"
            checked: root.targetConfig.utilities.gameMode.disableToastTransparency
            onToggled: {
                root.targetConfig.utilities.gameMode.disableToastTransparency = checked;
            }
        }
        ToggleRow {
            text: Tr.tr("Disable desktop lyrics")
            configNode: root.targetConfig.utilities.gameMode
            propertyName: "disableDesktopLyrics"
            checked: root.targetConfig.utilities.gameMode.disableDesktopLyrics
            onToggled: {
                root.targetConfig.utilities.gameMode.disableDesktopLyrics = checked;
            }
        }
        ToggleRow {
            text: Tr.tr("Disable visualizer")
            configNode: root.targetConfig.utilities.gameMode
            propertyName: "disableVisualizer"
            checked: root.targetConfig.utilities.gameMode.disableVisualizer
            onToggled: {
                root.targetConfig.utilities.gameMode.disableVisualizer = checked;
            }
        }
        ToggleRow {
            text: Tr.tr("Disable shimeji pets")
            last: true
            configNode: root.targetConfig.utilities.gameMode
            propertyName: "disableShimeji"
            checked: root.targetConfig.utilities.gameMode.disableShimeji
            onToggled: {
                root.targetConfig.utilities.gameMode.disableShimeji = checked;
            }
        }
    }
}
