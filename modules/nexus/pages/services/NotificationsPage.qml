import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import Caelestia.I18n
import qs.components.controls
import qs.modules.nexus.common

PageBase {
    id: root

    // Notification fullscreen visibility, ordered to match config::NotifsFullscreen (On, Off)
    readonly property list<MenuItem> notifFullscreenItems: [
        MenuItem {
            text: Tr.trCtx("On", "show notifications over fullscreen apps")
            icon: "notifications"
        },
        MenuItem {
            text: Tr.trCtx("Off", "show notifications over fullscreen apps")
            icon: "notifications_off"
        }
    ]

    // Toast fullscreen visibility, mapped to GlobalConfig.utilities.toasts.fullscreen
    readonly property list<MenuItem> toastFullscreenItems: [
        MenuItem {
            text: Tr.trCtx("Off", "show toasts over fullscreen apps")
            icon: "notifications_off"
        },
        MenuItem {
            text: Tr.trCtx("Important", "show toasts over fullscreen apps: important ones only")
            icon: "priority_high"
        },
        MenuItem {
            text: Tr.trCtx("On", "show toasts over fullscreen apps")
            icon: "notifications"
        }
    ]
    readonly property list<string> toastFullscreenValues: ["off", "important", "all"]

    title: Tr.tr("Notifications")
    isSubPage: true

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.extraSmall / 2

        // Notifications
        SectionHeader {
            first: true
            text: Tr.tr("Notifications")
        }

        SelectRow {
            first: true
<<<<<<< HEAD
            label: qsTr("Show in fullscreen")
            subtext: qsTr("Whether notifications appear over fullscreen apps")
            configNode: root.targetConfig.notifs
            propertyName: "fullscreen"
=======
            label: Tr.tr("Show in fullscreen")
            subtext: Tr.tr("Whether notifications appear over fullscreen apps")
>>>>>>> caelestia/main
            menuItems: root.notifFullscreenItems
            active: root.notifFullscreenItems[root.targetConfig.notifs.fullscreen]
            onSelected: item => {
                root.targetConfig.notifs.fullscreen = root.notifFullscreenItems.indexOf(item);
            }
        }

        ToggleRow {
<<<<<<< HEAD
            text: qsTr("Expire automatically")
            subtext: qsTr("Dismiss notifications after their timeout")
            configNode: root.targetConfig.notifs
            propertyName: "expire"
            checked: root.targetConfig.notifs.expire
            onToggled: {
                root.targetConfig.notifs.expire = checked;
            }
        }

        ToggleRow {
            text: qsTr("Open expanded")
            subtext: qsTr("Show notifications expanded by default")
            configNode: root.targetConfig.notifs
            propertyName: "openExpanded"
            checked: root.targetConfig.notifs.openExpanded
            onToggled: {
                root.targetConfig.notifs.openExpanded = checked;
            }
        }

        StepperRow {
            label: qsTr("Default timeout")
            subtext: qsTr("Time before a notification dismisses (ms)")
            configNode: root.targetConfig.notifs
            propertyName: "defaultExpireTimeout"
            value: root.targetConfig.notifs.defaultExpireTimeout
=======
            text: Tr.tr("Expire automatically")
            subtext: Tr.tr("Dismiss notifications after their timeout")
            checked: GlobalConfig.notifs.expire
            onToggled: GlobalConfig.notifs.expire = checked
        }

        ToggleRow {
            text: Tr.tr("Open expanded")
            subtext: Tr.tr("Show notifications expanded by default")
            checked: GlobalConfig.notifs.openExpanded
            onToggled: GlobalConfig.notifs.openExpanded = checked
        }

        StepperRow {
            label: Tr.tr("Default timeout")
            // TRANSLATORS: ms is the millisecond unit, leave it untranslated
            subtext: Tr.tr("Time before a notification dismisses (ms)")
            value: GlobalConfig.notifs.defaultExpireTimeout
>>>>>>> caelestia/main
            from: 1000
            to: 60000
            stepSize: 500
            onMoved: v => {
                root.targetConfig.notifs.defaultExpireTimeout = Math.round(v);
            }
        }

        StepperRow {
            last: true
<<<<<<< HEAD
            label: qsTr("Group preview count")
            subtext: qsTr("Notifications shown per group before collapsing")
            configNode: root.targetConfig.notifs
            propertyName: "groupPreviewNum"
            value: root.targetConfig.notifs.groupPreviewNum
=======
            label: Tr.tr("Group preview count")
            subtext: Tr.tr("Notifications shown per group before collapsing")
            value: GlobalConfig.notifs.groupPreviewNum
>>>>>>> caelestia/main
            from: 1
            to: 10
            stepSize: 1
            onMoved: v => {
                root.targetConfig.notifs.groupPreviewNum = Math.round(v);
            }
        }

        // Toasts
        SectionHeader {
            text: Tr.tr("Toasts")
        }

        SelectRow {
            first: true
<<<<<<< HEAD
            label: qsTr("Show in fullscreen")
            subtext: qsTr("Whether toasts appear over fullscreen apps")
            configNode: root.targetConfig.utilities.toasts
            propertyName: "fullscreen"
=======
            label: Tr.tr("Show in fullscreen")
            subtext: Tr.tr("Whether toasts appear over fullscreen apps")
>>>>>>> caelestia/main
            menuItems: root.toastFullscreenItems
            active: root.toastFullscreenItems[Math.max(0, root.toastFullscreenValues.indexOf(root.targetConfig.utilities.toasts.fullscreen))]
            onSelected: item => {
                root.targetConfig.utilities.toasts.fullscreen = root.toastFullscreenValues[root.toastFullscreenItems.indexOf(item)];
            }
        }

        StepperRow {
<<<<<<< HEAD
            label: qsTr("Visible toasts")
            subtext: qsTr("Maximum number of toasts shown at once")
            configNode: root.targetConfig.utilities
            propertyName: "maxToasts"
            value: root.targetConfig.utilities.maxToasts
=======
            last: true
            label: Tr.tr("Visible toasts")
            subtext: Tr.tr("Maximum number of toasts shown at once")
            value: GlobalConfig.utilities.maxToasts
>>>>>>> caelestia/main
            from: 1
            to: 10
            stepSize: 1
            onMoved: v => {
                root.targetConfig.utilities.maxToasts = Math.round(v);
            }
        }

        ToggleRow {
            text: qsTr("Toast transparency")
            subtext: qsTr("Apply transparency and blur to toast notifications")
            configNode: root.targetConfig.utilities.toasts
            propertyName: "transparency"
            checked: root.targetConfig.utilities.toasts.transparency
            onToggled: {
                root.targetConfig.utilities.toasts.transparency = checked;
            }
        }

        SliderRow {
            last: true
            label: qsTr("Base transparency")
            configNode: root.targetConfig.utilities.toasts
            propertyName: "transparencyBase"
            valueLabel: Math.round(value * 100) + "%"
            value: root.targetConfig.utilities.toasts.transparencyBase
            enabled: root.targetConfig.utilities.toasts.transparency
            onMoved: v => {
                root.targetConfig.utilities.toasts.transparencyBase = v;
            }
        }

        // Toast events
        SectionHeader {
            text: Tr.tr("Toast events")
        }

        ToggleRow {
            first: true
<<<<<<< HEAD
            text: qsTr("Charging changes")
            configNode: root.targetConfig.utilities.toasts
            propertyName: "chargingChanged"
            checked: root.targetConfig.utilities.toasts.chargingChanged
            onToggled: {
                root.targetConfig.utilities.toasts.chargingChanged = checked;
            }
        }

        ToggleRow {
            text: qsTr("Game mode changes")
            configNode: root.targetConfig.utilities.toasts
            propertyName: "gameModeChanged"
            checked: root.targetConfig.utilities.toasts.gameModeChanged
            onToggled: {
                root.targetConfig.utilities.toasts.gameModeChanged = checked;
            }
        }

        ToggleRow {
            text: qsTr("Do not disturb changes")
            configNode: root.targetConfig.utilities.toasts
            propertyName: "dndChanged"
            checked: root.targetConfig.utilities.toasts.dndChanged
            onToggled: {
                root.targetConfig.utilities.toasts.dndChanged = checked;
            }
        }

        ToggleRow {
            text: qsTr("Audio output changes")
            configNode: root.targetConfig.utilities.toasts
            propertyName: "audioOutputChanged"
            checked: root.targetConfig.utilities.toasts.audioOutputChanged
            onToggled: {
                root.targetConfig.utilities.toasts.audioOutputChanged = checked;
            }
        }

        ToggleRow {
            text: qsTr("Audio input changes")
            configNode: root.targetConfig.utilities.toasts
            propertyName: "audioInputChanged"
            checked: root.targetConfig.utilities.toasts.audioInputChanged
            onToggled: {
                root.targetConfig.utilities.toasts.audioInputChanged = checked;
            }
        }

        ToggleRow {
            text: qsTr("Caps lock changes")
            configNode: root.targetConfig.utilities.toasts
            propertyName: "capsLockChanged"
            checked: root.targetConfig.utilities.toasts.capsLockChanged
            onToggled: {
                root.targetConfig.utilities.toasts.capsLockChanged = checked;
            }
        }

        ToggleRow {
            text: qsTr("Num lock changes")
            configNode: root.targetConfig.utilities.toasts
            propertyName: "numLockChanged"
            checked: root.targetConfig.utilities.toasts.numLockChanged
            onToggled: {
                root.targetConfig.utilities.toasts.numLockChanged = checked;
            }
        }

        ToggleRow {
            text: qsTr("Keyboard layout changes")
            configNode: root.targetConfig.utilities.toasts
            propertyName: "kbLayoutChanged"
            checked: root.targetConfig.utilities.toasts.kbLayoutChanged
            onToggled: {
                root.targetConfig.utilities.toasts.kbLayoutChanged = checked;
            }
        }

        ToggleRow {
            text: qsTr("VPN changes")
            configNode: root.targetConfig.utilities.toasts
            propertyName: "vpnChanged"
            checked: root.targetConfig.utilities.toasts.vpnChanged
            onToggled: {
                root.targetConfig.utilities.toasts.vpnChanged = checked;
            }
=======
            text: Tr.tr("Charging changes")
            checked: GlobalConfig.utilities.toasts.chargingChanged
            onToggled: GlobalConfig.utilities.toasts.chargingChanged = checked
        }

        ToggleRow {
            text: Tr.tr("Game mode changes")
            checked: GlobalConfig.utilities.toasts.gameModeChanged
            onToggled: GlobalConfig.utilities.toasts.gameModeChanged = checked
        }

        ToggleRow {
            text: Tr.tr("Do not disturb changes")
            checked: GlobalConfig.utilities.toasts.dndChanged
            onToggled: GlobalConfig.utilities.toasts.dndChanged = checked
        }

        ToggleRow {
            text: Tr.tr("Audio output changes")
            checked: GlobalConfig.utilities.toasts.audioOutputChanged
            onToggled: GlobalConfig.utilities.toasts.audioOutputChanged = checked
        }

        ToggleRow {
            text: Tr.tr("Audio input changes")
            checked: GlobalConfig.utilities.toasts.audioInputChanged
            onToggled: GlobalConfig.utilities.toasts.audioInputChanged = checked
        }

        ToggleRow {
            text: Tr.tr("Caps lock changes")
            checked: GlobalConfig.utilities.toasts.capsLockChanged
            onToggled: GlobalConfig.utilities.toasts.capsLockChanged = checked
        }

        ToggleRow {
            text: Tr.tr("Num lock changes")
            checked: GlobalConfig.utilities.toasts.numLockChanged
            onToggled: GlobalConfig.utilities.toasts.numLockChanged = checked
        }

        ToggleRow {
            text: Tr.tr("Keyboard layout changes")
            checked: GlobalConfig.utilities.toasts.kbLayoutChanged
            onToggled: GlobalConfig.utilities.toasts.kbLayoutChanged = checked
        }

        ToggleRow {
            text: Tr.tr("VPN changes")
            checked: GlobalConfig.utilities.toasts.vpnChanged
            onToggled: GlobalConfig.utilities.toasts.vpnChanged = checked
>>>>>>> caelestia/main
        }

        ToggleRow {
            last: true
<<<<<<< HEAD
            text: qsTr("Now playing")
            configNode: root.targetConfig.utilities.toasts
            propertyName: "nowPlaying"
            checked: root.targetConfig.utilities.toasts.nowPlaying
            onToggled: {
                root.targetConfig.utilities.toasts.nowPlaying = checked;
            }
=======
            text: Tr.tr("Now playing")
            checked: GlobalConfig.utilities.toasts.nowPlaying
            onToggled: GlobalConfig.utilities.toasts.nowPlaying = checked
>>>>>>> caelestia/main
        }
    }
}
