pragma ComponentBehavior: Bound

import QtQuick.Layouts
import Caelestia.Config
import Caelestia.I18n
import qs.components.controls
import qs.modules.nexus.common

PageBase {
    id: root

    readonly property list<MenuItem> positionItems: [
        MenuItem {
            property string value: "top"

            text: Tr.tr("Top")
        },
        MenuItem {
            property string value: "bottom"

            text: Tr.tr("Bottom")
        },
        MenuItem {
            property string value: "left"

            text: Tr.tr("Left")
        },
        MenuItem {
            property string value: "right"

            text: Tr.tr("Right")
        }
    ]

    title: Tr.tr("Taskbar")    isSubPage: true

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
            text: Tr.tr("Persistent")
            subtext: Tr.tr("Keep the bar visible at all times")            configNode: root.targetConfig.bar
            propertyName: "persistent"
            checked: root.targetConfig.bar.persistent
            onToggled: {
                root.targetConfig.bar.persistent = checked;
            }
        }

        SelectRow {
            Layout.fillWidth: true
            label: Tr.tr("Position")
            subtext: Tr.tr("Screen edge to place the bar on")
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
            text: Tr.tr("Show on hover")
            subtext: Tr.tr("Reveal the bar when the cursor reaches the screen edge")            configNode: root.targetConfig.bar
            propertyName: "showOnHover"
            checked: root.targetConfig.bar.showOnHover
            onToggled: {
                root.targetConfig.bar.showOnHover = checked;
            }
        }

        StepperRow {
            last: true
            label: Tr.tr("Drag threshold")
            subtext: Tr.tr("Pixels dragged before the bar reveals")            configNode: root.targetConfig.bar
            propertyName: "dragThreshold"
            value: root.targetConfig.bar.dragThreshold
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
            text: Tr.tr("Taskbar components")
            subtext: Tr.tr("Add, remove or reorder components")
            onClicked: root.nState.openSubPage(6)
        }

        NavRow {
            icon: "workspaces"
            text: Tr.tr("Workspaces")
            subtext: Tr.tr("Indicators, window icons")            onClicked: root.nState.openSubPage(7)
        }

        NavRow {
            icon: "web_asset"
            text: Tr.tr("Active window")
            subtext: Tr.tr("Title display, popout")            onClicked: root.nState.openSubPage(8)
        }

        NavRow {
            icon: "dock"
            text: Tr.tr("Dock")
            subtext: Tr.tr("Positioning, recoloring")
            onClicked: root.nState.openSubPage(12)
        }

        NavRow {
            icon: "widgets"
            text: Tr.tr("Tray")
            subtext: Tr.tr("System tray icons")            onClicked: root.nState.openSubPage(9)
        }

        NavRow {
            icon: "signal_cellular_alt"
            text: Tr.tr("Status icons")
            subtext: Tr.tr("Visible indicators")            onClicked: root.nState.openSubPage(10)
        }

        NavRow {
            icon: "schedule"
            text: Tr.tr("Clock")
            subtext: Tr.tr("Date, icon, background")
            onClicked: root.nState.openSubPage(11)
        }

        NavRow {
            icon: "code"
            text: Tr.tr("GitHub")
            subtext: Tr.tr("Contributions, token setup")
            onClicked: root.nState.openSubPage(13)
        }

        NavRow {
            last: true
            icon: "music_note"
            text: Tr.tr("Spotify")
            subtext: Tr.tr("Visualizer, title length, background")
            onClicked: root.nState.openSubPage(14)
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
