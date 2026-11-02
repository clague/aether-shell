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

            ColumnLayout {
                id: pluginGroup

                required property var modelData
                required property int index

                // A plugin's options are shown on demand: loading every plugin's settings object
                // up front would instantiate QML for plugins the user never opens.
                property bool expanded: false

                readonly property bool hasSettings: (modelData.settingsSource ?? "") !== "" || (modelData.settingsUiSource ?? "") !== ""
                readonly property string ownUi: modelData.settingsUiSource ?? ""
                readonly property string settingsUrl: modelData.settingsSource ?? ""
                readonly property bool isLast: index === root.plugins.length - 1

                Layout.fillWidth: true
                spacing: Tokens.spacing.extraSmall / 2

                ToggleRow {
                    Layout.fillWidth: true
                    first: pluginGroup.index === 0
                    last: pluginGroup.isLast && !pluginGroup.expanded
                    text: pluginGroup.modelData.name ? `${pluginGroup.modelData.name} ${pluginGroup.modelData.version}` : pluginGroup.modelData.id
                    // A manifest that failed to load shows why instead of pretending to be a
                    // plugin the user can simply switch on.
                    subtext: pluginGroup.modelData.valid ? (pluginGroup.modelData.description || pluginGroup.modelData.author || pluginGroup.modelData.dir) : pluginGroup.modelData.error
                    enabled: pluginGroup.modelData.valid
                    checked: pluginGroup.modelData.enabled
                    onToggled: Plugins.setPluginEnabled(pluginGroup.modelData.id, checked)
                }

                RowButton {
                    Layout.fillWidth: true
                    visible: pluginGroup.hasSettings
                    last: pluginGroup.isLast && !pluginGroup.expanded
                    icon: "tune"
                    text: Tr.tr("Plugin settings")
                    trailingIcon: pluginGroup.expanded ? "expand_less" : "expand_more"
                    onClicked: pluginGroup.expanded = !pluginGroup.expanded
                }

                // The plugin's own UI wins when it ships one; otherwise the rows are generated
                // from its settings object (PluginSettings).
                Loader {
                    id: ownSettingsUi

                    Layout.fillWidth: true
                    active: pluginGroup.expanded && pluginGroup.ownUi !== ""
                    visible: active
                    source: active ? pluginGroup.ownUi : ""
                }

                Loader {
                    id: settingsObject

                    Layout.fillWidth: true
                    active: pluginGroup.expanded && pluginGroup.ownUi === "" && pluginGroup.settingsUrl !== ""
                    visible: active
                    source: active ? pluginGroup.settingsUrl : ""
                }

                PluginSettings {
                    Layout.fillWidth: true
                    visible: settingsObject.item !== null
                    settings: settingsObject.item
                }
            }
        }

        StyledText {
            Layout.fillWidth: true
            Layout.topMargin: Tokens.spacing.small
            visible: root.plugins.length === 0
            text: Tr.tr("No plugins installed. A plugin is a folder holding a manifest.json, placed in %1").arg(`~/.local/share/caelestia/plugins`)
            color: Colours.palette.m3outline
            font: Tokens.font.body.small
            wrapMode: Text.WordWrap
        }

        RowButton {
            Layout.topMargin: Tokens.spacing.small
            icon: "folder_open"
            text: Tr.tr("Open plugins folder")
            subtext: Tr.tr("Shell version %1").arg(Plugins.shellVersion)
            onClicked: Quickshell.execDetached(["xdg-open", `${Quickshell.env("HOME")}/.local/share/caelestia/plugins`])
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
