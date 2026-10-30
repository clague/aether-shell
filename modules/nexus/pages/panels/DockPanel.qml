pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import Aether.Config
import Aether.I18n
import qs.components
import qs.components.controls
import qs.modules.nexus.common

PageBase {
    id: root

    // Ordered to match config::HybridVariant (Midnight, Op)
    readonly property list<MenuItem> variantItems: [
        MenuItem {
            text: "MiDnight"
        },
        MenuItem {
            text: "OP"
        }
    ]

    function getAppName(appId: string): string {
        const entry = DesktopEntries.heuristicLookup(appId);
        return entry?.name ?? appId;
    }

    function getAppIcon(appId: string): string {
        const entry = DesktopEntries.heuristicLookup(appId);
        return entry?.icon ?? "application-x-executable";
    }

    function removePinnedApp(index: int): void {
        const list = [...GlobalConfig.dock.pinnedApps];
        list.splice(index, 1);
        GlobalConfig.dock.pinnedApps = list;
    }

    function addPinnedApp(appId: string): void {
        const list = [...GlobalConfig.dock.pinnedApps];
        if (!list.includes(appId)) {
            list.push(appId);
            GlobalConfig.dock.pinnedApps = list;
        }
    }

    title: Tr.tr("Dock")
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
            text: Tr.tr("Enabled")
            subtext: Tr.tr("Show the application dock at the bottom of the screen")
            checked: Config.dock.enabled
            onToggled: GlobalConfig.dock.enabled = checked
        }

        ToggleRow {
            text: Tr.tr("Show on hover")
            subtext: Config.dock.showOnHover ? Tr.tr("Reveal dock on hover (launcher opens on drag)") : Tr.tr("Reveal dock on drag (launcher opens on hover)")
            checked: Config.dock.showOnHover
            onToggled: {
                GlobalConfig.dock.showOnHover = checked;
                GlobalConfig.launcher.showOnHover = !checked;
            }
        }

        ToggleRow {
            last: true
            text: Tr.tr("Scroll to open launcher")
            subtext: Tr.tr("Scrolling over the dock opens the application launcher")
            checked: Config.dock.scrollToLauncher
            onToggled: GlobalConfig.dock.scrollToLauncher = checked
        }

        SectionHeader {
            text: Tr.tr("Implementation")
        }

        SelectRow {
            first: true
            last: true
            label: Tr.tr("Dock implementation")
            subtext: Tr.tr("MiDnight's bar section, or OP's auto-hiding panel")
            configNode: GlobalConfig.hybrid.variants
            propertyName: "dock"
            menuItems: root.variantItems
            active: root.variantItems[GlobalConfig.hybrid.variants.dock === HybridVariant.Op ? 1 : 0]
            onSelected: item => {
                GlobalConfig.hybrid.variants.dock = root.variantItems.indexOf(item) === 1 ? HybridVariant.Op : HybridVariant.Midnight;
            }
        }

        // Behaviour & Dimensions
        SectionHeader {
            text: Tr.tr("Behaviour & Sizing")
        }

        StepperRow {
            first: true
            label: Tr.tr("Maximum slots")
            subtext: Tr.tr("Max visible app slots before overflow scrolling")
            value: Config.dock.maxSlots
            from: 3
            to: 30
            stepSize: 1
            onMoved: v => GlobalConfig.dock.maxSlots = v
        }

        StepperRow {
            last: true
            label: Tr.tr("Drag threshold")
            subtext: Tr.tr("Pixels dragged before the dock reveals")
            value: Config.dock.dragThreshold
            from: 0
            to: 200
            stepSize: 5
            onMoved: v => GlobalConfig.dock.dragThreshold = v
        }

        // Pinned Applications
        SectionHeader {
            text: Tr.tr("Pinned applications")
        }

        Repeater {
            model: ScriptModel {
                values: [...GlobalConfig.dock.pinnedApps]
            }

            ConnectedRect {
                id: pinnedRow

                required property string modelData
                required property int index

                Layout.fillWidth: true
                first: index === 0
                last: false
                implicitHeight: rowLayout.implicitHeight + Tokens.padding.medium * 2

                RowLayout {
                    id: rowLayout

                    anchors.fill: parent
                    anchors.leftMargin: Tokens.padding.largeIncreased
                    anchors.rightMargin: Tokens.padding.medium
                    spacing: Tokens.spacing.medium

                    IconImage {
                        source: Quickshell.iconPath(root.getAppIcon(pinnedRow.modelData), "image-missing")
                        implicitWidth: 24
                        implicitHeight: 24
                    }

                    StyledText {
                        Layout.fillWidth: true
                        text: root.getAppName(pinnedRow.modelData)
                        font: Tokens.font.body.medium
                        elide: Text.ElideRight
                    }

                    IconButton {
                        icon: "close"
                        type: IconButton.Text
                        onClicked: root.removePinnedApp(pinnedRow.index)
                    }
                }
            }
        }

        DialogSelectButton {
            id: addAppContainer

            rootParent: root.flickable
            icon: "add"
            label: Tr.tr("Pin an app")
            header: Tr.tr("Choose application to pin")
            acceptLabel: Tr.tr("Pin")

            model: {
                const apps = [...DesktopEntries.applications.values].filter(a => a.id && a.name && !GlobalConfig.dock.pinnedApps.includes(a.id)).sort((a, b) => a.name.localeCompare(b.name)).map(a => ({
                            id: a.id,
                            label: a.name
                        }));
                return apps;
            }

            onAccepted: {
                if (selectedItem)
                    root.addPinnedApp(selectedItem);
            }
        }
    }
}
