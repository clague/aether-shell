import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import Caelestia.I18n
import qs.modules.nexus.common

PageBase {
    id: root

    title: Tr.tr("Shell Element Sizes")
    isSubPage: true

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: TokenConfig.appearance.spacing.extraSmall / 2

        SectionHeader {
            first: true
            text: Tr.tr("App Launcher")
        }

        StepperRow {
            first: true
            Layout.fillWidth: true
            label: Tr.tr("Item Width")
            value: TokenConfig.sizes.launcher.itemWidth
            from: 200
            to: 1000
            stepSize: 10
            showReset: true
            onMoved: v => TokenConfig.sizes.launcher.itemWidth = v
            onReset: {
                TokenConfig.sizes.launcher.resetOption("itemWidth");
            }        }

        StepperRow {
            Layout.topMargin: TokenConfig.appearance.spacing.extraSmall / 2 - parent.spacing
            Layout.fillWidth: true
            label: Tr.tr("Item Height")
            value: TokenConfig.sizes.launcher.itemHeight
            from: 20
            to: 150
            stepSize: 2
            showReset: true
            onMoved: v => TokenConfig.sizes.launcher.itemHeight = v
            onReset: {
                TokenConfig.sizes.launcher.resetOption("itemHeight");
            }        }

        StepperRow {
            Layout.topMargin: TokenConfig.appearance.spacing.extraSmall / 2 - parent.spacing
            Layout.fillWidth: true
            label: Tr.tr("Wallpaper Grid Width")
            value: TokenConfig.sizes.launcher.wallpaperWidth
            from: 100
            to: 500
            stepSize: 10
            showReset: true
            onMoved: v => TokenConfig.sizes.launcher.wallpaperWidth = v
            onReset: {
                TokenConfig.sizes.launcher.resetOption("wallpaperWidth");
            }        }

        StepperRow {
            Layout.topMargin: TokenConfig.appearance.spacing.extraSmall / 2 - parent.spacing
            last: true
            Layout.fillWidth: true
            label: Tr.tr("Wallpaper Grid Height")
            value: TokenConfig.sizes.launcher.wallpaperHeight
            from: 80
            to: 400
            stepSize: 10
            showReset: true
            onMoved: v => TokenConfig.sizes.launcher.wallpaperHeight = v
            onReset: {
                TokenConfig.sizes.launcher.resetOption("wallpaperHeight");
            }        }

        SectionHeader {
            text: Tr.tr("Notifications")
        }

        StepperRow {
            first: true
            Layout.fillWidth: true
            label: Tr.tr("Notification Width")
            value: TokenConfig.sizes.notifs.width
            from: 200
            to: 600
            stepSize: 10
            showReset: true
            onMoved: v => TokenConfig.sizes.notifs.width = v
            onReset: {
                TokenConfig.sizes.notifs.resetOption("width");
            }        }

        StepperRow {
            Layout.topMargin: TokenConfig.appearance.spacing.extraSmall / 2 - parent.spacing
            Layout.fillWidth: true
            label: Tr.tr("App Image Size")
            value: TokenConfig.sizes.notifs.image
            from: 16
            to: 96
            stepSize: 2
            showReset: true
            onMoved: v => TokenConfig.sizes.notifs.image = v
            onReset: {
                TokenConfig.sizes.notifs.resetOption("image");
            }        }

        StepperRow {
            Layout.topMargin: TokenConfig.appearance.spacing.extraSmall / 2 - parent.spacing
            last: true
            Layout.fillWidth: true
            label: Tr.tr("Badge Indicator Size")
            value: TokenConfig.sizes.notifs.badge
            from: 8
            to: 48
            stepSize: 2
            showReset: true
            onMoved: v => TokenConfig.sizes.notifs.badge = v
            onReset: {
                TokenConfig.sizes.notifs.resetOption("badge");
            }        }

        SectionHeader {
            text: Tr.tr("OSD & Volume Sliders")
        }

        StepperRow {
            first: true
            Layout.fillWidth: true
            label: Tr.tr("Slider Width")
            value: TokenConfig.sizes.osd.sliderWidth
            from: 8
            to: 100
            stepSize: 2
            showReset: true
            onMoved: v => TokenConfig.sizes.osd.sliderWidth = v
            onReset: {
                TokenConfig.sizes.osd.resetOption("sliderWidth");
            }        }

        StepperRow {
            Layout.topMargin: TokenConfig.appearance.spacing.extraSmall / 2 - parent.spacing
            last: true
            Layout.fillWidth: true
            label: Tr.tr("Slider Height")
            value: TokenConfig.sizes.osd.sliderHeight
            from: 50
            to: 400
            stepSize: 10
            showReset: true
            onMoved: v => TokenConfig.sizes.osd.sliderHeight = v
            onReset: {
                TokenConfig.sizes.osd.resetOption("sliderHeight");
            }        }

        SectionHeader {
            text: Tr.tr("Desktop Popouts & Panels")
        }

        StepperRow {
            first: true
            Layout.fillWidth: true
            label: Tr.tr("Session Menu Button Size")
            value: TokenConfig.sizes.session.button
            from: 40
            to: 150
            stepSize: 5
            showReset: true
            onMoved: v => TokenConfig.sizes.session.button = v
            onReset: {
                TokenConfig.sizes.session.resetOption("button");
            }        }

        StepperRow {
            Layout.topMargin: TokenConfig.appearance.spacing.extraSmall / 2 - parent.spacing
            Layout.fillWidth: true
            label: Tr.tr("Sidebar Width")
            value: TokenConfig.sizes.sidebar.width
            from: 200
            to: 600
            stepSize: 10
            showReset: true
            onMoved: v => TokenConfig.sizes.sidebar.width = v
            onReset: {
                TokenConfig.sizes.sidebar.resetOption("width");
            }        }

        StepperRow {
            Layout.topMargin: TokenConfig.appearance.spacing.extraSmall / 2 - parent.spacing
            Layout.fillWidth: true
            label: Tr.tr("Utilities Drawer Width")
            value: TokenConfig.sizes.utilities.width
            from: 200
            to: 600
            stepSize: 10
            showReset: true
            onMoved: v => TokenConfig.sizes.utilities.width = v
            onReset: {
                TokenConfig.sizes.utilities.resetOption("width");
            }        }

        StepperRow {
            Layout.topMargin: TokenConfig.appearance.spacing.extraSmall / 2 - parent.spacing
            last: true
            Layout.fillWidth: true
            label: Tr.tr("Toast Notification Width")
            value: TokenConfig.sizes.utilities.toastWidth
            from: 200
            to: 600
            stepSize: 10
            showReset: true
            onMoved: v => TokenConfig.sizes.utilities.toastWidth = v
            onReset: {
                TokenConfig.sizes.utilities.resetOption("toastWidth");
            }        }
    }
}
