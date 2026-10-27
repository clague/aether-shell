pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import Caelestia.I18n
import qs.modules.nexus.common

PageBase {
    id: root

    title: Tr.tr("Launcher")
    isSubPage: true

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.extraSmall / 2

        // General
        SectionHeader {
            first: true
            text: Tr.tr("General")
        }

        ToggleRow {
            first: true
<<<<<<< HEAD
            text: qsTr("Enabled")
            configNode: root.targetConfig.launcher
            propertyName: "enabled"
            checked: root.targetConfig.launcher.enabled
            onToggled: {
                root.targetConfig.launcher.enabled = checked;
            }
        }

        ToggleRow {
            text: qsTr("Show on hover")
            subtext: qsTr("Reveal when the cursor reaches the screen edge")
            configNode: root.targetConfig.launcher
            propertyName: "showOnHover"
            checked: root.targetConfig.launcher.showOnHover
            onToggled: {
                root.targetConfig.launcher.showOnHover = checked;
            }
=======
            text: Tr.trCtx("Enabled", "toggle label")
            checked: Config.launcher.enabled
            onToggled: GlobalConfig.launcher.enabled = checked
        }

        ToggleRow {
            text: Tr.tr("Show on hover")
            subtext: Tr.tr("Reveal when the cursor reaches the screen edge")
            checked: Config.launcher.showOnHover
            onToggled: GlobalConfig.launcher.showOnHover = checked
>>>>>>> caelestia/main
        }

        TextFieldRow {
            id: prefixRow

            last: true
<<<<<<< HEAD
            label: qsTr("Action prefix")
            subtext: qsTr("Prefix used to run actions in the launcher")
            configNode: root.targetConfig.launcher
            propertyName: "actionPrefix"
            errorText: qsTr("Prefix must not be alphanumeric")
            value: root.targetConfig.launcher.actionPrefix === ">" ? "" : root.targetConfig.launcher.actionPrefix
=======
            label: Tr.tr("Action prefix")
            subtext: Tr.tr("Prefix used to run actions in the launcher")
            errorText: Tr.tr("Prefix must not be alphanumeric")
            value: GlobalConfig.launcher.actionPrefix === ">" ? "" : GlobalConfig.launcher.actionPrefix // TODO: replace with empty only when not loaded once loaded state is exposed
>>>>>>> caelestia/main
            placeholderText: ">"
            maximumLength: 1
            smallField: true
            validate: /^[^a-zA-Z0-9\s]$/
            onEditingFinished: value => {
                if (!field.valid)
                    return;
                root.targetConfig.launcher.actionPrefix = value || ">";
                if (root.targetConfig.launcher.actionPrefix === ">")
                    clear();
            }
        }

        // Display
        SectionHeader {
            text: Tr.tr("Display")
        }

        StepperRow {
            first: true
<<<<<<< HEAD
            label: qsTr("Max items shown")
            configNode: root.targetConfig.launcher
            propertyName: "maxShown"
            value: root.targetConfig.launcher.maxShown
=======
            label: Tr.tr("Max items shown")
            value: Config.launcher.maxShown
>>>>>>> caelestia/main
            from: 1
            to: 20
            stepSize: 1
            onMoved: v => {
                root.targetConfig.launcher.maxShown = v;
            }
        }

        StepperRow {
<<<<<<< HEAD
            label: qsTr("Max wallpapers")
            configNode: root.targetConfig.launcher
            propertyName: "maxWallpapers"
            value: root.targetConfig.launcher.maxWallpapers
=======
            label: Tr.tr("Max wallpapers")
            value: Config.launcher.maxWallpapers
>>>>>>> caelestia/main
            from: 1
            to: 30
            stepSize: 1
            onMoved: v => {
                root.targetConfig.launcher.maxWallpapers = v;
            }
        }

        StepperRow {
            last: true
<<<<<<< HEAD
            label: qsTr("Drag threshold")
            subtext: qsTr("Pixels dragged before the launcher opens")
            configNode: root.targetConfig.launcher
            propertyName: "dragThreshold"
            value: root.targetConfig.launcher.dragThreshold
=======
            label: Tr.tr("Drag threshold")
            subtext: Tr.tr("Pixels dragged before the launcher opens")
            value: Config.launcher.dragThreshold
>>>>>>> caelestia/main
            from: 0
            to: 200
            stepSize: 5
            onMoved: v => {
                root.targetConfig.launcher.dragThreshold = v;
            }
        }

        // Behaviour
        SectionHeader {
            text: Tr.tr("Behaviour")
        }

        ToggleRow {
            first: true
<<<<<<< HEAD
            text: qsTr("Vim keybinds")
            subtext: qsTr("Navigate results with Ctrl+hjkl")
            configNode: root.targetConfig.launcher
            propertyName: "vimKeybinds"
            checked: root.targetConfig.launcher.vimKeybinds
            onToggled: {
                root.targetConfig.launcher.vimKeybinds = checked;
            }
=======
            text: Tr.tr("Vim keybinds")
            subtext: Tr.tr("Navigate results with Ctrl+hjkl")
            checked: GlobalConfig.launcher.vimKeybinds
            onToggled: GlobalConfig.launcher.vimKeybinds = checked
>>>>>>> caelestia/main
        }

        ToggleRow {
            last: true
<<<<<<< HEAD
            text: qsTr("Enable dangerous actions")
            subtext: qsTr("Allow actions that shut down or log out")
            configNode: root.targetConfig.launcher
            propertyName: "enableDangerousActions"
            checked: root.targetConfig.launcher.enableDangerousActions
            onToggled: {
                root.targetConfig.launcher.enableDangerousActions = checked;
            }
=======
            text: Tr.tr("Enable dangerous actions")
            subtext: Tr.tr("Allow actions that shut down or log out")
            checked: GlobalConfig.launcher.enableDangerousActions
            onToggled: GlobalConfig.launcher.enableDangerousActions = checked
>>>>>>> caelestia/main
        }

        // Fuzzy search
        SectionHeader {
            text: Tr.tr("Fuzzy search")
        }

        ToggleRow {
            first: true
<<<<<<< HEAD
            text: qsTr("Apps")
            configNode: root.targetConfig.launcher.useFuzzy
            propertyName: "apps"
            checked: root.targetConfig.launcher.useFuzzy.apps
            onToggled: {
                root.targetConfig.launcher.useFuzzy.apps = checked;
            }
        }

        ToggleRow {
            text: qsTr("Actions")
            configNode: root.targetConfig.launcher.useFuzzy
            propertyName: "actions"
            checked: root.targetConfig.launcher.useFuzzy.actions
            onToggled: {
                root.targetConfig.launcher.useFuzzy.actions = checked;
            }
        }

        ToggleRow {
            text: qsTr("Schemes")
            configNode: root.targetConfig.launcher.useFuzzy
            propertyName: "schemes"
            checked: root.targetConfig.launcher.useFuzzy.schemes
            onToggled: {
                root.targetConfig.launcher.useFuzzy.schemes = checked;
            }
        }

        ToggleRow {
            text: qsTr("Variants")
            configNode: root.targetConfig.launcher.useFuzzy
            propertyName: "variants"
            checked: root.targetConfig.launcher.useFuzzy.variants
            onToggled: {
                root.targetConfig.launcher.useFuzzy.variants = checked;
            }
=======
            text: Tr.tr("Apps")
            checked: GlobalConfig.launcher.useFuzzy.apps
            onToggled: GlobalConfig.launcher.useFuzzy.apps = checked
        }

        ToggleRow {
            text: Tr.tr("Actions")
            checked: GlobalConfig.launcher.useFuzzy.actions
            onToggled: GlobalConfig.launcher.useFuzzy.actions = checked
        }

        ToggleRow {
            text: Tr.tr("Schemes")
            checked: GlobalConfig.launcher.useFuzzy.schemes
            onToggled: GlobalConfig.launcher.useFuzzy.schemes = checked
        }

        ToggleRow {
            text: Tr.tr("Variants")
            checked: GlobalConfig.launcher.useFuzzy.variants
            onToggled: GlobalConfig.launcher.useFuzzy.variants = checked
>>>>>>> caelestia/main
        }

        ToggleRow {
            last: true
<<<<<<< HEAD
            text: qsTr("Wallpapers")
            configNode: root.targetConfig.launcher.useFuzzy
            propertyName: "wallpapers"
            checked: root.targetConfig.launcher.useFuzzy.wallpapers
            onToggled: {
                root.targetConfig.launcher.useFuzzy.wallpapers = checked;
            }
=======
            text: Tr.tr("Wallpapers")
            checked: GlobalConfig.launcher.useFuzzy.wallpapers
            onToggled: GlobalConfig.launcher.useFuzzy.wallpapers = checked
>>>>>>> caelestia/main
        }
    }
}
