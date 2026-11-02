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
            subtext: Tr.tr("Opacity, blur, shadows and window borders")
            onClicked: root.nState.openSubPage(1)
        }

        NavRow {
            icon: "space_dashboard"
            text: Tr.tr("Spacing & animations")
            subtext: Tr.tr("Window gaps and shared motion timing")
            onClicked: root.nState.openSubPage(2)
        }

        NavRow {
            icon: "data_object"
            text: Tr.tr("Variables")
            subtext: Tr.tr("Keybind apps, touchpad and misc variables")
            onClicked: root.nState.openSubPage(3)
        }

        NavRow {
            icon: "keyboard"
            text: Tr.tr("Keybinds")
            subtext: Tr.tr("Manage your hyprland keybinds")
            onClicked: root.nState.openSubPage(4)
        }

        NavRow {
            last: true
            icon: "settings_suggest"
            text: Tr.tr("User configuration")
            subtext: Tr.tr("Advanced configuration options")
            onClicked: root.nState.openSubPage(5)
        }

        // One note for the whole category instead of repeating it inside each sub-page. Most rows
        // write hypr-vars.lua (read by the Hyprland config at startup); Glass, Motion and the
        // spacing sliders are the exceptions -- they are pushed live and stored in the shell's
        // own state, so the note has to say so rather than claim the whole section is in the file.
        InfoRow {
            first: true
            last: true
            Layout.fillWidth: true
            Layout.topMargin: Tokens.spacing.large
            icon: "info"
            label: Tr.tr("Most settings are saved in hypr-vars.lua")
            subtext: Tr.tr("Glass, Motion and the spacing sliders apply live; clear a row to remove its override.")
        }
    }
}
