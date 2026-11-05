import QtQuick
import QtQuick.Layouts
import Aether.Config
import Aether.I18n
import qs.modules.nexus.common

PageBase {
    id: root

    title: Tr.tr("Hyprland")

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.extraSmall / 2

        NavRow {
            first: true
            icon: "blur_on"
            text: Tr.tr("Window effects")
            subtext: Tr.tr("Opacity, blur, shadows and window styling")
            onClicked: root.nState.openSubPage(1)
        }

        NavRow {
            icon: "space_dashboard"
            text: Tr.tr("Spacing & animations")
            subtext: Tr.tr("Gaps, window behaviour, layout and motion")
            onClicked: root.nState.openSubPage(2)
        }

        NavRow {
            icon: "mouse"
            text: Tr.tr("Input")
            subtext: Tr.tr("Keyboard, mouse, touchpad and gestures")
            onClicked: root.nState.openSubPage(3)
        }

        NavRow {
            icon: "keyboard"
            text: Tr.tr("Keybinds")
            subtext: Tr.tr("Workspaces, window actions and app shortcuts")
            onClicked: root.nState.openSubPage(4)
        }

        NavRow {
            icon: "data_object"
            text: Tr.tr("Variables")
            subtext: Tr.tr("Launcher apps, cursor and misc variables")
            onClicked: root.nState.openSubPage(5)
        }

        NavRow {
            last: true
            icon: "settings_suggest"
            text: Tr.tr("User configuration")
            subtext: Tr.tr("Advanced configuration options")
            onClicked: root.nState.openSubPage(6)
        }

        // One note for the whole category instead of repeating it inside each sub-page. Every
        // option here ends up in hypr-vars.lua: the plain rows write it directly, and Glass,
        // Motion and Density persist their values there too while still pushing them live.
        InfoRow {
            first: true
            last: true
            Layout.fillWidth: true
            Layout.topMargin: Tokens.spacing.large
            icon: "info"
            label: Tr.tr("Saved in hypr-vars.lua")
            subtext: Tr.tr("Hyprland reads it at startup, so settings survive restarts; clear a row to remove its override.")
        }
    }
}
