import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import Caelestia.I18n
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
            icon: "data_object"
            text: Tr.tr("Variables")
            subtext: Tr.tr("Default apps, touchpad and misc variables")
            onClicked: root.nState.openSubPage(1)
        }

        NavRow {
            icon: "keyboard"
            text: Tr.tr("Keybinds")
            subtext: Tr.tr("Manage your hyprland keybinds")
            onClicked: root.nState.openSubPage(2)
        }

        NavRow {
            last: true
            icon: "settings_suggest"
            text: Tr.tr("User configuration")
            subtext: Tr.tr("Advanced configuration options")
            onClicked: root.nState.openSubPage(3)
        }
    }
}
