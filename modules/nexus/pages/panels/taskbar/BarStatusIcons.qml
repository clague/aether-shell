pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
<<<<<<< HEAD
import qs.components
import qs.services
=======
import Caelestia.I18n
>>>>>>> caelestia/main
import qs.modules.nexus.common

PageBase {
    id: root

    readonly property var builtinIcons: ({
<<<<<<< HEAD
            lockStatus: qsTr("Lock keys"),
            kbLayout: qsTr("Keyboard layout"),
            audio: qsTr("Speakers"),
            microphone: qsTr("Microphone"),
            network: qsTr("Network"),
            bluetooth: qsTr("Bluetooth"),
            battery: qsTr("Battery"),
            peripheralBattery: qsTr("Peripheral battery"),
            notifications: qsTr("Notifications")
=======
            lockStatus: Tr.tr("Lock keys"),
            kbLayout: Tr.tr("Keyboard layout"),
            audio: Tr.tr("Speakers"),
            microphone: Tr.tr("Microphone"),
            network: Tr.tr("Network"),
            bluetooth: Tr.tr("Bluetooth"),
            battery: Tr.tr("Battery")
>>>>>>> caelestia/main
        })

    title: Tr.tr("Status icons")
    isSubPage: true

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.extraSmall / 2

        // Visible icons
<<<<<<< HEAD
        RowLayout {
            Layout.fillWidth: true
            Layout.leftMargin: Tokens.padding.small

            StyledText {
                text: qsTr("Visible icons")
                color: Colours.palette.m3onSurfaceVariant
                font: Tokens.font.label.medium
                elide: Text.ElideRight
            }

            PerMonitorStatusChip {
                configNode: root.targetConfig.bar
                propertyName: "statusIcons"
            }

            Item {
                Layout.fillWidth: true
            }
=======
        SectionHeader {
            first: true
            text: Tr.tr("Visible icons")
>>>>>>> caelestia/main
        }

        ListEditor {
            function labelFor(item: var): string {
                const prettyName = root.builtinIcons[item.id];
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
            values: root.targetConfig.bar.statusIcons.values
            onItemMoved: (from, to) => {
                root.targetConfig.bar.statusIcons.move(from, to);
            }
            onItemRemoved: index => {
                root.targetConfig.bar.statusIcons.remove(index);
            }
            onItemToggled: (index, checked) => {
                root.targetConfig.bar.statusIcons.at(index).enabled = checked;
            }
        }

        DialogSelectButton {
            id: addItemContainer

            rootParent: root.flickable
            icon: "add"
            label: Tr.tr("Add entry")
            header: Tr.tr("Add new entry")
            acceptLabel: Tr.trCtx("Add", "button")

            model: {
                const builtins = Object.keys(root.builtinIcons).map(k => ({
                            id: k,
                            label: root.builtinIcons[k]
                        }));
                return builtins;
            }

            onAccepted: {
                if (!selectedItem) // Should never happen but just in case
                    return;

                root.targetConfig.bar.statusIcons.insert({
                    id: selectedItem,
                    enabled: true
                });
            }
        }

        // Behaviour
        SectionHeader {
            text: Tr.tr("Behaviour")
        }

        ToggleRow {
            first: true
            last: true
<<<<<<< HEAD
            text: qsTr("Popout on hover")
            subtext: qsTr("Show a details popout when hovering the status icons")
            configNode: root.targetConfig.bar.popouts
            propertyName: "statusIcons"
            checked: root.targetConfig.bar.popouts.statusIcons
            onToggled: {
                root.targetConfig.bar.popouts.statusIcons = checked;
            }
=======
            text: Tr.tr("Popout on hover")
            subtext: Tr.tr("Show a details popout when hovering the status icons")
            checked: Config.bar.popouts.statusIcons
            onToggled: GlobalConfig.bar.popouts.statusIcons = checked
>>>>>>> caelestia/main
        }
    }
}
