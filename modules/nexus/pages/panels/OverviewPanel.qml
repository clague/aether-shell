pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import Caelestia.I18n
import qs.components
import qs.components.controls
import qs.services
import qs.modules.overview
import qs.modules.nexus.common

PageBase {
    id: root

    readonly property list<MenuItem> tabItems: [
        MenuItem {
            text: Tr.tr("Workspaces carousel")
            icon: "view_carousel"
        },
        MenuItem {
            text: Tr.tr("Special scratchpads")
            icon: "layers"
        },
        MenuItem {
            text: Tr.tr("All windows grid")
            icon: "grid_view"
        }
    ]

    title: Tr.tr("Taskview")
    isSubPage: true

    ColumnLayout {
        anchors.horizontalCenter: parent?.horizontalCenter
        anchors.top: parent?.top
        width: root.cappedWidth
        spacing: Tokens.spacing.extraSmall / 2

        // View options
        SectionHeader {
            first: true
            text: Tr.tr("View options")
        }

        SelectRow {
            first: true
            last: true
            label: Tr.tr("Active tab")
            subtext: Tr.tr("Initial view when opening the fullscreen overview")
            menuItems: root.tabItems
            active: root.tabItems[Math.max(0, Math.min(2, OverviewState.activeTab))]
            onSelected: item => OverviewState.activeTab = root.tabItems.indexOf(item)
        }

        // Integration & Controls
        SectionHeader {
            text: Tr.tr("Shortcuts & Gestures")
        }

        ConnectedRect {
            Layout.fillWidth: true
            first: true
            last: true
            implicitHeight: infoLayout.implicitHeight + Tokens.padding.medium * 2

            ColumnLayout {
                id: infoLayout

                anchors.fill: parent
                anchors.margins: Tokens.padding.medium
                anchors.leftMargin: Tokens.padding.largeIncreased
                anchors.rightMargin: Tokens.padding.largeIncreased
                spacing: Tokens.spacing.small

                RowLayout {
                    spacing: Tokens.spacing.small

                    MaterialIcon {
                        text: "keyboard"
                        color: Colours.palette.m3primary
                    }

                    StyledText {
                        text: Tr.tr("Shortcut toggle")
                        font: Tokens.font.body.medium
                    }
                }

                StyledText {
                    Layout.fillWidth: true
                    text: Tr.tr("Press your configured overview hotkey or run `caelestia ipc overview toggle` to open the taskview at any time.")
                    color: Colours.palette.m3onSurfaceVariant
                    font: Tokens.font.body.small
                    wrapMode: Text.WordWrap
                }
            }
        }
    }
}
