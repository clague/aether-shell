pragma ComponentBehavior: Bound

import QtQuick.Layouts
import Caelestia.Config
import Caelestia.I18n
import qs.modules.nexus.common

PageBase {
    id: root

    title: Tr.tr("Active window")
    isSubPage: true

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.extraSmall / 2

        ToggleRow {
            first: true
<<<<<<< HEAD
            text: qsTr("Enable component")
            checked: {
                const entries = Config.bar.entries;
                for (const section of [entries.start, entries.center, entries.end]) {
                    for (let i = 0; i < section.count; i++) {
                        if (section.at(i).id === "activeWindow")
                            return section.at(i).enabled;
                    }
                }
                return false;
            }
            onToggled: {
                const entries = GlobalConfig.bar.entries;
                for (const section of [entries.start, entries.center, entries.end]) {
                    for (let i = 0; i < section.count; i++) {
                        if (section.at(i).id === "activeWindow") {
                            section.at(i).enabled = checked;
                            return;
                        }
                    }
                }
                entries.center.insert({
                    id: "activeWindow",
                    enabled: checked
                });
            }
        }

        ToggleRow {
            Layout.fillWidth: true
            text: qsTr("Compact")
            configNode: root.targetConfig.bar.activeWindow
            propertyName: "compact"
            checked: root.targetConfig.bar.activeWindow.compact
            onToggled: {
                root.targetConfig.bar.activeWindow.compact = checked;
            }
        }

        ToggleRow {
            text: qsTr("Inverted")
            configNode: root.targetConfig.bar.activeWindow
            propertyName: "inverted"
            checked: root.targetConfig.bar.activeWindow.inverted
            onToggled: {
                root.targetConfig.bar.activeWindow.inverted = checked;
            }
        }

        ToggleRow {
            text: qsTr("Show on hover")
            subtext: qsTr("Only show the active window title while hovering")
            configNode: root.targetConfig.bar.activeWindow
            propertyName: "showOnHover"
            checked: root.targetConfig.bar.activeWindow.showOnHover
            onToggled: {
                root.targetConfig.bar.activeWindow.showOnHover = checked;
            }
=======
            text: Tr.trCtx("Compact", "taskbar active window layout")
            checked: Config.bar.activeWindow.compact
            onToggled: GlobalConfig.bar.activeWindow.compact = checked
        }

        ToggleRow {
            text: Tr.trCtx("Inverted", "taskbar active window: swap the title and class order")
            checked: Config.bar.activeWindow.inverted
            onToggled: GlobalConfig.bar.activeWindow.inverted = checked
        }

        ToggleRow {
            text: Tr.tr("Show on hover")
            subtext: Tr.tr("Only show the active window title while hovering")
            checked: Config.bar.activeWindow.showOnHover
            onToggled: GlobalConfig.bar.activeWindow.showOnHover = checked
>>>>>>> caelestia/main
        }

        ToggleRow {
            last: true
<<<<<<< HEAD
            text: qsTr("Popout on hover")
            subtext: qsTr("Show a window details popout when hovering")
            configNode: root.targetConfig.bar.popouts
            propertyName: "activeWindow"
            checked: root.targetConfig.bar.popouts.activeWindow
            onToggled: {
                root.targetConfig.bar.popouts.activeWindow = checked;
            }
=======
            text: Tr.tr("Popout on hover")
            subtext: Tr.tr("Show a window details popout when hovering")
            checked: Config.bar.popouts.activeWindow
            onToggled: GlobalConfig.bar.popouts.activeWindow = checked
>>>>>>> caelestia/main
        }
    }
}
