import QtQuick
import QtQuick.Layouts
import Aether
import Aether.Config
import Aether.I18n
import qs.components
import qs.components.controls
import qs.services
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

        // This page only exists while developer mode is on (About, seven taps on the
        // version). Without a way back out the sidebar entry is permanent, so the switch
        // lives where Android puts it: inside the developer options themselves.
        SectionHeader {
            Layout.topMargin: Tokens.padding.large
            text: Tr.tr("Developer Options")
        }

        StyledText {
            Layout.fillWidth: true
            Layout.leftMargin: Tokens.padding.medium
            Layout.rightMargin: Tokens.padding.medium
            text: Tr.tr("Shell Tokens is a developer page. Turning it off hides it from the sidebar; tap the version in About seven times to bring it back.")
            color: Colours.palette.m3onSurfaceVariant
            font: Tokens.font.body.small
            wrapMode: Text.WordWrap
        }

        IconTextButton {
            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: Tokens.padding.medium
            icon: "lock"
            text: Tr.tr("Turn off developer options")
            type: IconTextButton.Tonal
            onClicked: {
                // Leave first: the page is removed from the navigation as soon as developer
                // mode is off, and staying on it would show a page that no longer exists.
                root.nState.openPageByKey("about");
                GlobalConfig.general.developerMode = false;
                Toaster.toast(Tr.tr("Developer Options"), Tr.tr("Turned off. Shell Tokens is hidden from the sidebar."), "lock");
            }
        }
    }
}
