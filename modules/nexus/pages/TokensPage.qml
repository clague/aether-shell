import QtQuick.Layouts
import Aether.Config
import Aether.I18n
import qs.modules.nexus.common

PageBase {
    id: root

    title: Tr.tr("Shell Tokens")

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: TokenConfig.appearance.spacing.extraSmall / 2

        SectionHeader {
            first: true
            text: Tr.tr("General")
        }

        NavRow {
            first: true
            icon: "grid_view"
            text: Tr.tr("Rounding & Spacing")
            subtext: Tr.tr("Adjust outer margins, paddings, and corner rounding")
            onClicked: root.nState.openSubPage(1)
        }

        NavRow {
            icon: "format_size"
            text: Tr.tr("Font Sizes")
            subtext: Tr.tr("Set typography scaling for interface text")
            onClicked: root.nState.openSubPage(2)
        }

        NavRow {
            icon: "space_dashboard"
            text: Tr.tr("Bar & Dashboard Sizes")
            subtext: Tr.tr("Adjust widths of top bar widgets and dashboard tiles")
            onClicked: root.nState.openSubPage(3)
        }

        NavRow {
            icon: "desktop_windows"
            text: Tr.tr("Window & Lock Sizes")
            subtext: Tr.tr("Modify proportions for main settings window and lock screen")
            onClicked: root.nState.openSubPage(4)
        }

        NavRow {
            last: true
            icon: "widgets"
            text: Tr.tr("Shell Element Sizes")
            subtext: Tr.tr("Configure launcher grid, notifications, OSD, and sidebars")
            onClicked: root.nState.openSubPage(5)
        }
    }
}
