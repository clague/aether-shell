pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.modules.nexus.common

PageBase {
    id: root

    readonly property var builtinComponents: ({
            logo: Tr.tr("Logo"),
            workspaces: Tr.tr("Workspaces"),
            github: Tr.tr("GitHub"),
            spotify: Tr.tr("Spotify"),
            spacer: Tr.tr("Spacer"),
            activeWindow: Tr.tr("Active window"),
            tray: Tr.tr("System tray"),
            clock: Tr.tr("Clock"),
            statusIcons: Tr.tr("Status icons"),
            dock: Tr.tr("Dock"),
            power: Tr.tr("Power menu")
        })

    readonly property bool isHorizontal: root.targetConfig.bar.position === "top" || root.targetConfig.bar.position === "bottom"
    readonly property string startLabel: isHorizontal ? Tr.tr("Left") : Tr.tr("Top")
    readonly property string endLabel: isHorizontal ? Tr.tr("Right") : Tr.tr("Bottom")

    title: Tr.tr("Taskbar components")
    isSubPage: true

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.extraSmall / 2

        EntrySectionEditor {
            sectionLabel: root.startLabel
            targetList: root.targetConfig.bar.entries.start
            first: true
        }

        EntrySectionEditor {
            sectionLabel: Tr.tr("Center")
            targetList: root.targetConfig.bar.entries.center
        }

        EntrySectionEditor {
            sectionLabel: root.endLabel
            targetList: root.targetConfig.bar.entries.end
        }
    }

    component EntrySectionEditor: ColumnLayout {
        id: sectionEditor

        required property string sectionLabel
        required property var targetList
        property bool first

        spacing: Tokens.spacing.extraSmall / 2

        SectionHeader {
            first: sectionEditor.first
            text: sectionEditor.sectionLabel
        }

        ListEditor {
            function labelFor(item: var): string {
                const prettyName = root.builtinComponents[item.id];
                if (prettyName)
                    return prettyName;
                const label = item.id.replace(/([A-Z])/g, " $1");
                return label.charAt(0).toUpperCase() + label.slice(1).toLowerCase();
            }

            function toggledFor(item: var): bool {
                return item.enabled;
            }

            z: 1
            first: true
            values: sectionEditor.targetList.values
            onItemMoved: (from, to) => {
                sectionEditor.targetList.move(from, to);
            }
            onItemRemoved: index => {
                sectionEditor.targetList.remove(index);
            }
            onItemToggled: (index, checked) => {
                sectionEditor.targetList.at(index).enabled = checked;
            }
        }

        DialogSelectButton {
            rootParent: root.flickable
            icon: "add"
            label: Tr.tr("Add entry")
            header: Tr.tr("Add new entry")
            acceptLabel: Tr.tr("Add")

            model: {
                const builtins = Object.keys(root.builtinComponents).map(k => ({
                            id: k,
                            label: root.builtinComponents[k]
                        }));
                return builtins;
            }

            onAccepted: {
                if (!selectedItem) // Should never happen but just in case
                    return;

                sectionEditor.targetList.insert({
                    id: selectedItem,
                    enabled: true
                });
            }
        }
    }
}
