pragma ComponentBehavior: Bound

import QtQuick.Layouts
import Aether.Config
import Aether.I18n
import qs.modules.nexus.common

PageBase {
    id: root

    title: Tr.tr("Dock")
    isSubPage: true

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.extraSmall / 2

        ToggleRow {
            Layout.fillWidth: true
            first: true
            text: Tr.tr("Enable component")
            checked: {
                const entries = Config.bar.entries;
                for (const section of [entries.start, entries.center, entries.end]) {
                    for (let i = 0; i < section.count; i++) {
                        if (section.at(i).id === "dock")
                            return section.at(i).enabled;
                    }
                }
                return false;
            }
            onToggled: {
                const entries = GlobalConfig.bar.entries;
                for (const section of [entries.start, entries.center, entries.end]) {
                    for (let i = 0; i < section.count; i++) {
                        if (section.at(i).id === "dock") {
                            section.at(i).enabled = checked;
                            return;
                        }
                    }
                }
                entries.start.insert({
                    id: "dock",
                    enabled: checked
                });
            }
        }

        ToggleRow {
            Layout.fillWidth: true
            text: Tr.tr("Monitor center")
            subtext: Tr.tr("Center the dock relative to the physical monitor")
            configNode: root.targetConfig.bar.dock
            propertyName: "monitorCenter"
            checked: root.targetConfig.bar.dock.monitorCenter
            onToggled: {
                root.targetConfig.bar.dock.monitorCenter = checked;
            }
        }

        ToggleRow {
            Layout.fillWidth: true
            last: true
            text: Tr.tr("Recolour icons")
            subtext: Tr.tr("Recolour application icons using the system theme")
            configNode: root.targetConfig.bar.dock
            propertyName: "recolourIcons"
            checked: root.targetConfig.bar.dock.recolourIcons
            onToggled: {
                root.targetConfig.bar.dock.recolourIcons = checked;
            }
        }
    }
}
