import QtQuick.Layouts
import Aether.Config
import Aether.I18n
import qs.modules.nexus.common

PageBase {
    id: root

    title: Tr.tr("Panels")

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.extraSmall / 2

        NavRow {
            first: true
            icon: "dashboard"
            text: Tr.tr("Dashboard")
            subtext: Config.dashboard.enabled ? Tr.trCtx("Enabled", "panel status") : Tr.trCtx("Disabled", "panel status")
            onClicked: root.nState.openSubPage(1)
        }

        NavRow {
            icon: "dock_to_bottom"
            text: Tr.tr("Taskbar")
            subtext: Config.bar.persistent ? Tr.tr("Always visible") : Config.bar.showOnHover ? Tr.tr("Reveal on hover") : Tr.tr("Reveal on drag")
            onClicked: root.nState.openSubPage(2)
        }

        NavRow {
            icon: "apps"
            text: Tr.tr("Launcher")
            subtext: Config.launcher.enabled ? Tr.trCtx("Enabled", "panel status") : Tr.trCtx("Disabled", "panel status")
            onClicked: root.nState.openSubPage(3)
        }

        NavRow {
            icon: "dock_to_right"
            text: Tr.tr("Sidebar")
            subtext: Config.sidebar.enabled ? Tr.trCtx("Enabled", "panel status") : Tr.trCtx("Disabled", "panel status")
            onClicked: root.nState.openSubPage(4)
        }

        NavRow {
            icon: "construction"
            text: Tr.tr("Utilities")
            subtext: Config.utilities.enabled ? Tr.trCtx("Enabled", "panel status") : Tr.trCtx("Disabled", "panel status")
            onClicked: root.nState.openSubPage(5)
        }

        NavRow {
            icon: "branding_watermark"
            text: Tr.tr("On-screen display")
            subtext: Config.osd.enabled ? Tr.trCtx("Enabled", "panel status") : Tr.trCtx("Disabled", "panel status")
            onClicked: root.nState.openSubPage(6)
        }

        NavRow {
            icon: "view_carousel"
            text: Tr.tr("Taskview (Overview)")
            subtext: Tr.tr("Workspaces & window overview")
            onClicked: root.nState.openSubPage(7)
        }

        NavRow {
            icon: "dock"
            text: Tr.tr("Dock")
            subtext: Config.dock.enabled ? Tr.trCtx("Enabled", "panel status") : Tr.trCtx("Disabled", "panel status")
            onClicked: root.nState.openSubPage(8)
        }

        NavRow {
            last: true
            icon: "sticky_note_2"
            text: Tr.tr("Scratchpad & Notes")
            subtext: Tr.tr("Scratchpad directory & custom tags")
            onClicked: root.nState.openSubPage(18)
        }
    }
}
