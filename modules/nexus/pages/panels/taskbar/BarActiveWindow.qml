pragma ComponentBehavior: Bound

import QtQuick.Layouts
import Aether.Config
import Aether.I18n
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
            text: Tr.tr("Enable component")
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
            text: Tr.tr("Compact")
            configNode: root.targetConfig.bar.activeWindow
            propertyName: "compact"
            checked: root.targetConfig.bar.activeWindow.compact
            onToggled: {
                root.targetConfig.bar.activeWindow.compact = checked;
            }
        }

        ToggleRow {
            text: Tr.tr("Inverted")
            configNode: root.targetConfig.bar.activeWindow
            propertyName: "inverted"
            checked: root.targetConfig.bar.activeWindow.inverted
            onToggled: {
                root.targetConfig.bar.activeWindow.inverted = checked;
            }
        }

        ToggleRow {
            text: Tr.tr("Show on hover")
            subtext: Tr.tr("Only show the active window title while hovering")
            configNode: root.targetConfig.bar.activeWindow
            propertyName: "showOnHover"
            checked: root.targetConfig.bar.activeWindow.showOnHover
            onToggled: {
                root.targetConfig.bar.activeWindow.showOnHover = checked;
            }
        }

        ToggleRow {
            last: true
            text: Tr.tr("Popout on hover")
            subtext: Tr.tr("Show a window details popout when hovering")
            configNode: root.targetConfig.bar.popouts
            propertyName: "activeWindow"
            checked: root.targetConfig.bar.popouts.activeWindow
            onToggled: {
                root.targetConfig.bar.popouts.activeWindow = checked;
            }
        }
    }
}
