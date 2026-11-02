pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Aether.Config
import Aether.I18n
import Aether.Plugins
import qs.components
import qs.services
import qs.modules.nexus.common

PageBase {
    id: root

    // The backend rescans on its file watcher and bumps this list; binding to it keeps the page
    // live when a plugin is dropped in or removed while the settings window is open.
    readonly property var plugins: Plugins.plugins

    title: Tr.tr("Plugins")

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.extraSmall / 2

        SectionHeader {
            first: true
            text: Tr.tr("Installed plugins")
        }

        Repeater {
            model: root.plugins

            ToggleRow {
                required property var modelData
                required property int index

                first: index === 0
                last: index === root.plugins.length - 1
                text: modelData.name ? `${modelData.name} ${modelData.version}` : modelData.id
                // A manifest that failed to load shows why instead of pretending to be a plugin
                // the user can simply switch on.
                subtext: modelData.valid ? (modelData.description || modelData.author || modelData.dir) : modelData.error
                enabled: modelData.valid
                checked: modelData.enabled
                onToggled: Plugins.setPluginEnabled(modelData.id, checked)
            }
        }

        StyledText {
            Layout.fillWidth: true
            Layout.topMargin: Tokens.spacing.small
            visible: root.plugins.length === 0
            text: Tr.tr("No plugins installed. A plugin is a folder with a plugin.json dropped into %1").arg(`~/.config/caelestia/plugins`)
            color: Colours.palette.m3outline
            font: Tokens.font.body.small
            wrapMode: Text.WordWrap
        }

        RowButton {
            Layout.topMargin: Tokens.spacing.small
            icon: "folder_open"
            text: Tr.tr("Open plugins folder")
            subtext: Tr.tr("Shell version %1").arg(Plugins.shellVersion)
            onClicked: Quickshell.execDetached(["xdg-open", `${Quickshell.env("HOME")}/.config/caelestia/plugins`])
        }

        RowButton {
            last: true
            icon: "refresh"
            text: Tr.tr("Rescan plugins")
            subtext: Tr.tr("Reload manifests and entry points without restarting the shell")
            onClicked: Plugins.reload()
        }
    }
}
