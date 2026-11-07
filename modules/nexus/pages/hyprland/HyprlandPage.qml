import QtQuick
import QtQuick.Layouts
import Aether.Config
import Aether.I18n
import qs.services
import qs.modules.nexus.common

PageBase {
    id: root

    title: Tr.tr("Hyprland")

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.extraSmall / 2

        InfoRow {
            first: true
            last: true
            visible: !Hypr.configInstalled
            Layout.fillWidth: true
            Layout.bottomMargin: Tokens.spacing.large
            icon: "warning"
            label: Tr.tr("Aether's Hyprland config is not installed")
            subtext: Tr.tr("The pages below write hypr-vars.lua, and only Aether's hyprland.lua reads it. Run `aether hypr install` once; it backs up ~/.config/hypr and links the config in place.")
        }

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
            last: true
            icon: "data_object"
            text: Tr.tr("Variables")
            subtext: Tr.tr("Launcher apps, cursor and misc variables")
            onClicked: root.nState.openSubPage(5)
        }

        // One note for the five settings pages above. User configuration is deliberately not
        // part of it: that page edits hypr-user.lua, not the hypr-vars.lua overrides.
        InfoRow {
            first: true
            last: true
            Layout.fillWidth: true
            Layout.topMargin: Tokens.spacing.large
            icon: "info"
            label: Tr.tr("Saved in hypr-vars.lua")
            subtext: Tr.tr("The settings above write overrides to hypr-vars.lua; Hyprland reads it at startup. Clear a row to remove its override.")
        }

        NavRow {
            first: true
            last: true
            Layout.topMargin: Tokens.spacing.large
            icon: "settings_suggest"
            text: Tr.tr("User configuration")
            subtext: Tr.tr("Edit hypr-user.lua for anything not covered above")
            onClicked: root.nState.openSubPage(6)
        }
    }
}
