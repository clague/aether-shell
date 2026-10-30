pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import M3Shapes
import Caelestia.Config
import Caelestia.I18n
import qs.components.controls
import qs.modules.nexus.common

PageBase {
    id: root

    readonly property list<MenuItem> dashboardShapeItems: [
        MenuItem {
            property int value: MaterialShape.Circle

            text: Tr.tr("Circle")
        },
        MenuItem {
            property int value: MaterialShape.Square

            text: Tr.tr("Square")
        },
        MenuItem {
            property int value: MaterialShape.Pill

            text: Tr.tr("Pill")
        },
        MenuItem {
            property int value: MaterialShape.Diamond

            text: Tr.tr("Diamond")
        },
        MenuItem {
            property int value: MaterialShape.ClamShell

            text: Tr.tr("Clam Shell")
        },
        MenuItem {
            property int value: MaterialShape.Pentagon

            text: Tr.tr("Pentagon")
        },
        MenuItem {
            property int value: MaterialShape.Gem

            text: Tr.tr("Gem")
        },
        MenuItem {
            property int value: MaterialShape.Cookie4Sided

            text: Tr.tr("Cookie 4-Sided")
        },
        MenuItem {
            property int value: MaterialShape.Cookie6Sided

            text: Tr.tr("Cookie 6-Sided")
        },
        MenuItem {
            property int value: MaterialShape.Cookie7Sided

            text: Tr.tr("Cookie 7-Sided")
        },
        MenuItem {
            property int value: MaterialShape.Cookie9Sided

            text: Tr.tr("Cookie 9-Sided")
        },
        MenuItem {
            property int value: MaterialShape.Cookie12Sided

            text: Tr.tr("Cookie 12-Sided")
        }
    ]

    readonly property list<MenuItem> lockShapeItems: [
        MenuItem {
            property int value: MaterialShape.Circle

            text: Tr.tr("Circle")
        },
        MenuItem {
            property int value: MaterialShape.Square

            text: Tr.tr("Square")
        },
        MenuItem {
            property int value: MaterialShape.Pill

            text: Tr.tr("Pill")
        },
        MenuItem {
            property int value: MaterialShape.Diamond

            text: Tr.tr("Diamond")
        },
        MenuItem {
            property int value: MaterialShape.ClamShell

            text: Tr.tr("Clam Shell")
        },
        MenuItem {
            property int value: MaterialShape.Pentagon

            text: Tr.tr("Pentagon")
        },
        MenuItem {
            property int value: MaterialShape.Gem

            text: Tr.tr("Gem")
        },
        MenuItem {
            property int value: MaterialShape.Cookie4Sided

            text: Tr.tr("Cookie 4-Sided")
        },
        MenuItem {
            property int value: MaterialShape.Cookie6Sided

            text: Tr.tr("Cookie 6-Sided")
        },
        MenuItem {
            property int value: MaterialShape.Cookie7Sided

            text: Tr.tr("Cookie 7-Sided")
        },
        MenuItem {
            property int value: MaterialShape.Cookie9Sided

            text: Tr.tr("Cookie 9-Sided")
        },
        MenuItem {
            property int value: MaterialShape.Cookie12Sided

            text: Tr.tr("Cookie 12-Sided")
        }
    ]

    title: Tr.tr("Dashboard")
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
            text: Tr.tr("Enabled")
            configNode: root.targetConfig.dashboard
            propertyName: "enabled"
            checked: root.targetConfig.dashboard.enabled
            onToggled: {
                root.targetConfig.dashboard.enabled = checked;
            }
        }

        ToggleRow {
            Layout.fillWidth: true
            text: Tr.tr("Show on hover")
            subtext: Tr.tr("Reveal when the cursor reaches the screen edge")
            configNode: root.targetConfig.dashboard
            propertyName: "showOnHover"
            checked: root.targetConfig.dashboard.showOnHover
            onToggled: {
                root.targetConfig.dashboard.showOnHover = checked;
            }
        }

        SelectRow {
            Layout.fillWidth: true
            label: Tr.tr("Dashboard profile picture shape")
            subtext: Tr.tr("Choose the shape of the profile picture on the dashboard")
            configNode: root.targetConfig.dashboard
            propertyName: "profilePicShape"
            fallbackIcon: "person"
            fallbackText: Tr.tr("Pill")
            active: {
                for (let i = 0; i < root.dashboardShapeItems.length; i++) {
                    if (root.dashboardShapeItems[i].value === root.targetConfig.dashboard.profilePicShape)
                        return root.dashboardShapeItems[i];
                }
                return root.dashboardShapeItems[0];
            }
            menuItems: root.dashboardShapeItems
            onSelected: item => {
                root.targetConfig.dashboard.profilePicShape = item.value; // qmllint disable missing-property
            }
        }

        SelectRow {
            Layout.fillWidth: true
            last: true
            label: Tr.tr("Lock screen profile picture shape")
            subtext: Tr.tr("Choose the shape of the profile picture on the lock screen")
            configNode: root.targetConfig.lock
            propertyName: "profilePicShape"
            fallbackIcon: "lock"
            fallbackText: Tr.tr("Clam Shell")
            active: {
                for (let i = 0; i < root.lockShapeItems.length; i++) {
                    if (root.lockShapeItems[i].value === root.targetConfig.lock.profilePicShape)
                        return root.lockShapeItems[i];
                }
                return root.lockShapeItems[0];
            }
            menuItems: root.lockShapeItems
            onSelected: item => {
                root.targetConfig.lock.profilePicShape = item.value; // qmllint disable missing-property
            }
        }

        ToggleRow {
            last: true
            text: qsTr("Show clock seconds")
            subtext: qsTr("Display seconds for the clock in the main panel")
            configNode: root.targetConfig.dashboard
            propertyName: "showClockSeconds"
            checked: root.targetConfig.dashboard.showClockSeconds
            onToggled: {
                root.targetConfig.dashboard.showClockSeconds = checked;
                root.targetConfig.save();
            }
        }

        // Tabs
        SectionHeader {
            text: Tr.tr("Tabs")
        }

        ToggleRow {
            first: true
            text: Tr.tr("Dashboard")
            configNode: root.targetConfig.dashboard
            propertyName: "showDashboard"
            checked: root.targetConfig.dashboard.showDashboard
            onToggled: {
                root.targetConfig.dashboard.showDashboard = checked;
            }
        }

        ToggleRow {
            text: Tr.tr("Media")
            configNode: root.targetConfig.dashboard
            propertyName: "showMedia"
            checked: root.targetConfig.dashboard.showMedia
            onToggled: {
                root.targetConfig.dashboard.showMedia = checked;
            }
        }

        ToggleRow {
            text: Tr.tr("Performance")
            configNode: root.targetConfig.dashboard
            propertyName: "showPerformance"
            checked: root.targetConfig.dashboard.showPerformance
            onToggled: {
                root.targetConfig.dashboard.showPerformance = checked;
            }
        }

        ToggleRow {
            Layout.fillWidth: true
            text: Tr.tr("Weather")
            configNode: root.targetConfig.dashboard
            propertyName: "showWeather"
            checked: root.targetConfig.dashboard.showWeather
            onToggled: {
                root.targetConfig.dashboard.showWeather = checked;
            }
        }

        ToggleRow {
            Layout.fillWidth: true
            last: true
            text: Tr.tr("Terminal")
            configNode: root.targetConfig.dashboard
            propertyName: "showTerminal"
            checked: root.targetConfig.dashboard.showTerminal
            onToggled: {
                root.targetConfig.dashboard.showTerminal = checked;
            }
        }

        // Splash
        SectionHeader {
            text: Tr.tr("Splash")
        }

        ToggleRow {
            first: true
            last: true
            Layout.fillWidth: true
            text: Tr.tr("Hyprland splash")
            subtext: Tr.tr("Show the current Hyprland splash text")
            configNode: root.targetConfig.dashboard
            propertyName: "showHyprlandSplash"
            checked: root.targetConfig.dashboard.showHyprlandSplash
            onToggled: {
                root.targetConfig.dashboard.showHyprlandSplash = checked;
            }
        }

        // Media
        SectionHeader {
            text: Tr.tr("Media")
        }

        ToggleRow {
            first: true
            Layout.fillWidth: true
            text: Tr.tr("Recolor media GIF")
            subtext: Tr.tr("Apply system theme colors to the media GIF")
            configNode: root.targetConfig.dashboard
            propertyName: "colorizeMediaGif"
            checked: root.targetConfig.dashboard.colorizeMediaGif
            onToggled: {
                root.targetConfig.dashboard.colorizeMediaGif = checked;
            }
        }

        ToggleRow {
            Layout.fillWidth: true
            text: Tr.tr("Use material shapes")
            subtext: Tr.tr("Replace the media GIF with audio-reactive material shapes")
            configNode: root.targetConfig.dashboard
            propertyName: "useMediaShapes"
            checked: root.targetConfig.dashboard.useMediaShapes
            onToggled: {
                root.targetConfig.dashboard.useMediaShapes = checked;
            }
        }

        ToggleRow {
            Layout.fillWidth: true
            text: Tr.tr("Randomize shape colors")
            subtext: Tr.tr("Randomly shift shape colors while morphing")
            configNode: root.targetConfig.dashboard
            propertyName: "randomizeMediaShapeColors"
            checked: root.targetConfig.dashboard.randomizeMediaShapeColors
            onToggled: {
                root.targetConfig.dashboard.randomizeMediaShapeColors = checked;
            }
        }

        ToggleRow {
            Layout.fillWidth: true
            text: Tr.tr("Sync with music")
            subtext: Tr.tr("Randomly pick shapes to the beat instead of bass level")
            configNode: root.targetConfig.dashboard
            propertyName: "syncMediaShapesToBeat"
            checked: root.targetConfig.dashboard.syncMediaShapesToBeat
            onToggled: {
                root.targetConfig.dashboard.syncMediaShapesToBeat = checked;
            }
        }

        ToggleRow {
            last: true
            Layout.fillWidth: true
            text: Tr.tr("Replace lyrics with visuals")
            subtext: Tr.tr("Show the GIF/shapes in the media tab instead of lyrics")
            configNode: root.targetConfig.dashboard
            propertyName: "replaceMediaLyricsWithVisuals"
            checked: root.targetConfig.dashboard.replaceMediaLyricsWithVisuals
            onToggled: {
                root.targetConfig.dashboard.replaceMediaLyricsWithVisuals = checked;
            }
        }

        // Weather
        SectionHeader {
            text: Tr.tr("Weather")
        }

        ToggleRow {
            first: true
            last: true
            Layout.fillWidth: true
            text: Tr.tr("Weather location")
            subtext: Tr.tr("Show the location in the weather tab")
            configNode: root.targetConfig.dashboard
            propertyName: "showWeatherLocation"
            checked: root.targetConfig.dashboard.showWeatherLocation !== false
            onToggled: {
                root.targetConfig.dashboard.showWeatherLocation = checked;
            }
        }

        // Performance widgets
        SectionHeader {
            text: Tr.tr("Performance widgets")
        }

        ToggleRow {
            first: true
            text: Tr.tr("Battery")
            configNode: root.targetConfig.dashboard.performance
            propertyName: "showBattery"
            checked: root.targetConfig.dashboard.performance.showBattery
            onToggled: {
                root.targetConfig.dashboard.performance.showBattery = checked;
            }
        }

        ToggleRow {
            text: Tr.tr("GPU")
            configNode: root.targetConfig.dashboard.performance
            propertyName: "showGpu"
            checked: root.targetConfig.dashboard.performance.showGpu
            onToggled: {
                root.targetConfig.dashboard.performance.showGpu = checked;
            }
        }

        ToggleRow {
            text: Tr.tr("CPU")
            configNode: root.targetConfig.dashboard.performance
            propertyName: "showCpu"
            checked: root.targetConfig.dashboard.performance.showCpu
            onToggled: {
                root.targetConfig.dashboard.performance.showCpu = checked;
            }
        }

        ToggleRow {
            text: Tr.tr("Memory")
            configNode: root.targetConfig.dashboard.performance
            propertyName: "showMemory"
            checked: root.targetConfig.dashboard.performance.showMemory
            onToggled: {
                root.targetConfig.dashboard.performance.showMemory = checked;
            }
        }

        ToggleRow {
            text: Tr.tr("Storage")
            configNode: root.targetConfig.dashboard.performance
            propertyName: "showStorage"
            checked: root.targetConfig.dashboard.performance.showStorage
            onToggled: {
                root.targetConfig.dashboard.performance.showStorage = checked;
            }
        }

        ToggleRow {
            last: true
            text: Tr.tr("Network")
            configNode: root.targetConfig.dashboard.performance
            propertyName: "showNetwork"
            checked: root.targetConfig.dashboard.performance.showNetwork
            onToggled: {
                root.targetConfig.dashboard.performance.showNetwork = checked;
            }
        }

        // Behaviour
        SectionHeader {
            text: Tr.tr("Behaviour")
        }

        // Pomodoro
        SectionHeader {
            text: Tr.tr("Pomodoro")
        }

        ToggleRow {
            first: true
            Layout.fillWidth: true
            text: Tr.tr("Default to Pomodoro")
            subtext: Tr.tr("Show the timer instead of the clock when the dashboard opens")
            configNode: root.targetConfig.dashboard.pomodoro
            propertyName: "defaultToPomodoro"
            checked: root.targetConfig.dashboard.pomodoro.defaultToPomodoro
            onToggled: {
                root.targetConfig.dashboard.pomodoro.defaultToPomodoro = checked;
            }
        }

        StepperRow {
            Layout.fillWidth: true
            label: Tr.tr("Focus duration")
            subtext: Tr.tr("Minutes per focus session")
            configNode: root.targetConfig.dashboard.pomodoro
            propertyName: "focusDuration"
            value: root.targetConfig.dashboard.pomodoro.focusDuration
            from: 1
            to: 120
            stepSize: 1
            onMoved: v => {
                root.targetConfig.dashboard.pomodoro.focusDuration = v;
            }
        }

        StepperRow {
            Layout.fillWidth: true
            label: Tr.tr("Short break")
            subtext: Tr.tr("Minutes per short break")
            configNode: root.targetConfig.dashboard.pomodoro
            propertyName: "shortBreakDuration"
            value: root.targetConfig.dashboard.pomodoro.shortBreakDuration
            from: 1
            to: 60
            stepSize: 1
            onMoved: v => {
                root.targetConfig.dashboard.pomodoro.shortBreakDuration = v;
            }
        }

        StepperRow {
            Layout.fillWidth: true
            label: Tr.tr("Long break")
            subtext: Tr.tr("Minutes per long break")
            configNode: root.targetConfig.dashboard.pomodoro
            propertyName: "longBreakDuration"
            value: root.targetConfig.dashboard.pomodoro.longBreakDuration
            from: 1
            to: 120
            stepSize: 1
            onMoved: v => {
                root.targetConfig.dashboard.pomodoro.longBreakDuration = v;
            }
        }

        StepperRow {
            Layout.fillWidth: true
            last: true
            label: Tr.tr("Sessions before a long break")
            configNode: root.targetConfig.dashboard.pomodoro
            propertyName: "sessionsBeforeLongBreak"
            value: root.targetConfig.dashboard.pomodoro.sessionsBeforeLongBreak
            from: 1
            to: 12
            stepSize: 1
            onMoved: v => {
                root.targetConfig.dashboard.pomodoro.sessionsBeforeLongBreak = v;
            }
        }

        StepperRow {
            first: true
            last: true
            label: Tr.tr("Drag threshold")
            subtext: Tr.tr("Pixels dragged before the dashboard opens")
            configNode: root.targetConfig.dashboard
            propertyName: "dragThreshold"
            value: root.targetConfig.dashboard.dragThreshold
            from: 0
            to: 200
            stepSize: 5
            onMoved: v => {
                root.targetConfig.dashboard.dragThreshold = v;
            }
        }
    }
}
