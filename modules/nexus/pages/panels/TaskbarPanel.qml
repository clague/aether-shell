pragma ComponentBehavior: Bound

import QtQuick.Layouts
import Caelestia.Config
<<<<<<< HEAD
import qs.components.controls
=======
import Caelestia.I18n
>>>>>>> caelestia/main
import qs.modules.nexus.common

PageBase {
    id: root

<<<<<<< HEAD
    readonly property list<MenuItem> positionItems: [
        MenuItem {
            property string value: "top"

            text: qsTr("Top")
        },
        MenuItem {
            property string value: "bottom"

            text: qsTr("Bottom")
        },
        MenuItem {
            property string value: "left"

            text: qsTr("Left")
        },
        MenuItem {
            property string value: "right"

            text: qsTr("Right")
        }
    ]

    title: qsTr("Taskbar")
=======
    title: Tr.tr("Taskbar")
>>>>>>> caelestia/main
    isSubPage: true

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.extraSmall / 2

        // Behaviour
        SectionHeader {
            first: true
            text: Tr.tr("Behaviour")
        }

        ToggleRow {
            first: true
<<<<<<< HEAD
            text: qsTr("Persistent")
            subtext: qsTr("Keep the bar visible at all times")
            configNode: root.targetConfig.bar
            propertyName: "persistent"
            checked: root.targetConfig.bar.persistent
            onToggled: {
                root.targetConfig.bar.persistent = checked;
            }
        }

        SelectRow {
            Layout.fillWidth: true
            label: qsTr("Position")
            subtext: qsTr("Screen edge to place the bar on")
            configNode: root.targetConfig.bar
            propertyName: "position"
            active: {
                for (let i = 0; i < root.positionItems.length; i++) {
                    if (root.positionItems[i].value === root.targetConfig.bar.position)
                        return root.positionItems[i];
                }
                return root.positionItems[0];
            }
            menuItems: root.positionItems
            onSelected: item => {
                root.targetConfig.bar.position = item.value; // qmllint disable missing-property
            }
        }

        ToggleRow {
            text: qsTr("Show on hover")
            subtext: qsTr("Reveal the bar when the cursor reaches the screen edge")
            configNode: root.targetConfig.bar
            propertyName: "showOnHover"
            checked: root.targetConfig.bar.showOnHover
            onToggled: {
                root.targetConfig.bar.showOnHover = checked;
            }
=======
            text: Tr.tr("Persistent")
            subtext: Tr.tr("Keep the bar visible at all times")
            checked: Config.bar.persistent
            onToggled: GlobalConfig.bar.persistent = checked
        }

        ToggleRow {
            text: Tr.tr("Show on hover")
            subtext: Tr.tr("Reveal the bar when the cursor reaches the screen edge")
            checked: Config.bar.showOnHover
            onToggled: GlobalConfig.bar.showOnHover = checked
>>>>>>> caelestia/main
        }

        StepperRow {
            last: true
<<<<<<< HEAD
            label: qsTr("Drag threshold")
            subtext: qsTr("Pixels dragged before the bar reveals")
            configNode: root.targetConfig.bar
            propertyName: "dragThreshold"
            value: root.targetConfig.bar.dragThreshold
=======
            label: Tr.tr("Drag threshold")
            subtext: Tr.tr("Pixels dragged before the bar reveals")
            value: Config.bar.dragThreshold
>>>>>>> caelestia/main
            from: 0
            to: 200
            stepSize: 5
            onMoved: v => {
                root.targetConfig.bar.dragThreshold = v;
            }
        }

        // Components
        SectionHeader {
            text: Tr.tr("Components")
        }

        NavRow {
            first: true
            icon: "view_agenda"
            text: qsTr("Taskbar components")
            subtext: qsTr("Add, remove or reorder components")
            onClicked: root.nState.openSubPage(6)
        }

        NavRow {
            icon: "workspaces"
<<<<<<< HEAD
            text: qsTr("Workspaces")
            subtext: qsTr("Indicators, window icons")
            onClicked: root.nState.openSubPage(7)
=======
            text: Tr.tr("Workspaces")
            subtext: Tr.tr("Indicators, window icons")
            onClicked: root.nState.openSubPage(6)
>>>>>>> caelestia/main
        }

        NavRow {
            icon: "web_asset"
<<<<<<< HEAD
            text: qsTr("Active window")
            subtext: qsTr("Title display, popout")
            onClicked: root.nState.openSubPage(8)
        }

        NavRow {
            icon: "dock"
            text: qsTr("Dock")
            subtext: qsTr("Positioning, recoloring")
            onClicked: root.nState.openSubPage(12)
=======
            text: Tr.tr("Active window")
            subtext: Tr.tr("Title display, popout")
            onClicked: root.nState.openSubPage(7)
>>>>>>> caelestia/main
        }

        NavRow {
            icon: "widgets"
<<<<<<< HEAD
            text: qsTr("Tray")
            subtext: qsTr("System tray icons")
            onClicked: root.nState.openSubPage(9)
=======
            text: Tr.tr("Tray")
            subtext: Tr.tr("System tray icons")
            onClicked: root.nState.openSubPage(8)
>>>>>>> caelestia/main
        }

        NavRow {
            icon: "signal_cellular_alt"
<<<<<<< HEAD
            text: qsTr("Status icons")
            subtext: qsTr("Visible indicators")
            onClicked: root.nState.openSubPage(10)
        }

        NavRow {
            icon: "schedule"
            text: qsTr("Clock")
            subtext: qsTr("Date, icon, background")
            onClicked: root.nState.openSubPage(11)
        }

        NavRow {
            icon: "code"
            text: qsTr("GitHub")
            subtext: qsTr("Contributions, token setup")
            onClicked: root.nState.openSubPage(13)
=======
            text: Tr.tr("Status icons")
            subtext: Tr.tr("Visible indicators")
            onClicked: root.nState.openSubPage(9)
>>>>>>> caelestia/main
        }

        NavRow {
            last: true
<<<<<<< HEAD
            icon: "music_note"
            text: qsTr("Spotify")
            subtext: qsTr("Visualizer, title length, background")
            onClicked: root.nState.openSubPage(14)
=======
            icon: "schedule"
            text: Tr.tr("Clock")
            subtext: Tr.tr("Date, icon, background")
            onClicked: root.nState.openSubPage(10)
>>>>>>> caelestia/main
        }

        // Scroll actions
        SectionHeader {
            text: Tr.tr("Scroll actions")
        }

        ToggleRow {
            first: true
            text: Tr.tr("Workspaces")
            subtext: Tr.tr("Scroll over the workspace indicator to switch workspaces")
            checked: Config.bar.scrollActions.workspaces
            onToggled: GlobalConfig.bar.scrollActions.workspaces = checked
        }

        ToggleRow {
            text: Tr.tr("Volume")
            subtext: Tr.tr("Scroll on the top half of the bar to adjust volume")
            checked: Config.bar.scrollActions.volume
            onToggled: GlobalConfig.bar.scrollActions.volume = checked
        }

        ToggleRow {
            last: true
            text: Tr.tr("Brightness")
            subtext: Tr.tr("Scroll on the bottom half of the bar to adjust brightness")
            checked: Config.bar.scrollActions.brightness
            onToggled: GlobalConfig.bar.scrollActions.brightness = checked
        }
    }
}
