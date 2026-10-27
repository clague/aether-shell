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
            label: Tr.tr("Show in fullscreen")
            subtext: Tr.tr("Whether notifications appear over fullscreen apps")
            configNode: root.targetConfig.notifs
            propertyName: "fullscreen"            menuItems: root.notifFullscreenItems
            active: root.notifFullscreenItems[root.targetConfig.notifs.fullscreen]
            onSelected: item => {
                root.targetConfig.notifs.fullscreen = root.notifFullscreenItems.indexOf(item);
            }
        }

        ToggleRow {
            text: Tr.tr("Expire automatically")
            subtext: Tr.tr("Dismiss notifications after their timeout")
            configNode: root.targetConfig.notifs
            propertyName: "expire"
            checked: root.targetConfig.notifs.expire
            onToggled: {
                root.targetConfig.notifs.expire = checked;
            }
        }

        ToggleRow {
            text: Tr.tr("Open expanded")
            subtext: Tr.tr("Show notifications expanded by default")
            configNode: root.targetConfig.notifs
            propertyName: "openExpanded"
            checked: root.targetConfig.notifs.openExpanded
            onToggled: {
                root.targetConfig.notifs.openExpanded = checked;
            }
        }

        StepperRow {
            label: Tr.tr("Default timeout")
            subtext: Tr.tr("Time before a notification dismisses (ms)")
            configNode: root.targetConfig.notifs
            propertyName: "defaultExpireTimeout"
            value: root.targetConfig.notifs.defaultExpireTimeout            from: 1000
            to: 60000
            stepSize: 500
            onMoved: v => {
                root.targetConfig.notifs.defaultExpireTimeout = Math.round(v);
            }
        }

        StepperRow {
            last: true
            label: Tr.tr("Group preview count")
            subtext: Tr.tr("Notifications shown per group before collapsing")
            configNode: root.targetConfig.notifs
            propertyName: "groupPreviewNum"
            value: root.targetConfig.notifs.groupPreviewNum            from: 1
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
            label: Tr.tr("Show in fullscreen")
            subtext: Tr.tr("Whether toasts appear over fullscreen apps")
            configNode: root.targetConfig.utilities.toasts
            propertyName: "fullscreen"            menuItems: root.toastFullscreenItems
            active: root.toastFullscreenItems[Math.max(0, root.toastFullscreenValues.indexOf(root.targetConfig.utilities.toasts.fullscreen))]
            onSelected: item => {
                root.targetConfig.utilities.toasts.fullscreen = root.toastFullscreenValues[root.toastFullscreenItems.indexOf(item)];
            }
        }

        StepperRow {
            label: Tr.tr("Visible toasts")
            subtext: Tr.tr("Maximum number of toasts shown at once")
            configNode: root.targetConfig.utilities
            propertyName: "maxToasts"
            value: root.targetConfig.utilities.maxToasts            from: 1
            to: 10
            stepSize: 1
            onMoved: v => {
                root.targetConfig.utilities.maxToasts = Math.round(v);
            }
        }

        ToggleRow {
            text: Tr.tr("Toast transparency")
            subtext: Tr.tr("Apply transparency and blur to toast notifications")
            configNode: root.targetConfig.utilities.toasts
            propertyName: "transparency"
            checked: root.targetConfig.utilities.toasts.transparency
            onToggled: {
                root.targetConfig.utilities.toasts.transparency = checked;
            }
        }

        SliderRow {
            last: true
            label: Tr.tr("Base transparency")
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
            text: Tr.tr("Charging changes")
            configNode: root.targetConfig.utilities.toasts
            propertyName: "chargingChanged"
            checked: root.targetConfig.utilities.toasts.chargingChanged
            onToggled: {
                root.targetConfig.utilities.toasts.chargingChanged = checked;
            }
        }

        ToggleRow {
            text: Tr.tr("Game mode changes")
            configNode: root.targetConfig.utilities.toasts
            propertyName: "gameModeChanged"
            checked: root.targetConfig.utilities.toasts.gameModeChanged
            onToggled: {
                root.targetConfig.utilities.toasts.gameModeChanged = checked;
            }
        }

        ToggleRow {
            text: Tr.tr("Do not disturb changes")
            configNode: root.targetConfig.utilities.toasts
            propertyName: "dndChanged"
            checked: root.targetConfig.utilities.toasts.dndChanged
            onToggled: {
                root.targetConfig.utilities.toasts.dndChanged = checked;
            }
        }

        ToggleRow {
            text: Tr.tr("Audio output changes")
            configNode: root.targetConfig.utilities.toasts
            propertyName: "audioOutputChanged"
            checked: root.targetConfig.utilities.toasts.audioOutputChanged
            onToggled: {
                root.targetConfig.utilities.toasts.audioOutputChanged = checked;
            }
        }

        ToggleRow {
            text: Tr.tr("Audio input changes")
            configNode: root.targetConfig.utilities.toasts
            propertyName: "audioInputChanged"
            checked: root.targetConfig.utilities.toasts.audioInputChanged
            onToggled: {
                root.targetConfig.utilities.toasts.audioInputChanged = checked;
            }
        }

        ToggleRow {
            text: Tr.tr("Caps lock changes")
            configNode: root.targetConfig.utilities.toasts
            propertyName: "capsLockChanged"
            checked: root.targetConfig.utilities.toasts.capsLockChanged
            onToggled: {
                root.targetConfig.utilities.toasts.capsLockChanged = checked;
            }
        }

        ToggleRow {
            text: Tr.tr("Num lock changes")
            configNode: root.targetConfig.utilities.toasts
            propertyName: "numLockChanged"
            checked: root.targetConfig.utilities.toasts.numLockChanged
            onToggled: {
                root.targetConfig.utilities.toasts.numLockChanged = checked;
            }
        }

        ToggleRow {
            text: Tr.tr("Keyboard layout changes")
            configNode: root.targetConfig.utilities.toasts
            propertyName: "kbLayoutChanged"
            checked: root.targetConfig.utilities.toasts.kbLayoutChanged
            onToggled: {
                root.targetConfig.utilities.toasts.kbLayoutChanged = checked;
            }
        }

        ToggleRow {
            text: Tr.tr("VPN changes")
            configNode: root.targetConfig.utilities.toasts
            propertyName: "vpnChanged"
            checked: root.targetConfig.utilities.toasts.vpnChanged
            onToggled: {
                root.targetConfig.utilities.toasts.vpnChanged = checked;
            }        }

        ToggleRow {
            last: true
            text: Tr.tr("Now playing")
            configNode: root.targetConfig.utilities.toasts
            propertyName: "nowPlaying"
            checked: root.targetConfig.utilities.toasts.nowPlaying
            onToggled: {
                root.targetConfig.utilities.toasts.nowPlaying = checked;
            }        }
    }
}
