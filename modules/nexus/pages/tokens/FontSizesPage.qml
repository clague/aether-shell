import QtQuick
import QtQuick.Layouts
import Aether.Config
import Aether.I18n
import qs.modules.nexus.common

PageBase {
    id: root

    title: Tr.tr("Font Sizes")
    isSubPage: true

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: TokenConfig.appearance.spacing.extraSmall / 2

        SectionHeader {
            first: true
            text: Tr.tr("Standard Fonts")
        }

        StepperRow {
            first: true
            Layout.fillWidth: true
            label: Tr.tr("Small")
            value: TokenConfig.appearance.fontSize.small
            from: 6
            to: 36
            stepSize: 1
            showReset: true
            onMoved: v => TokenConfig.appearance.fontSize.small = v
            onReset: {
                TokenConfig.appearance.fontSize.resetOption("small");
            }
        }

        StepperRow {
            Layout.topMargin: TokenConfig.appearance.spacing.extraSmall / 2 - parent.spacing
            Layout.fillWidth: true
            label: Tr.tr("Smaller")
            value: TokenConfig.appearance.fontSize.smaller
            from: 6
            to: 36
            stepSize: 1
            showReset: true
            onMoved: v => TokenConfig.appearance.fontSize.smaller = v
            onReset: {
                TokenConfig.appearance.fontSize.resetOption("smaller");
            }
        }

        StepperRow {
            Layout.topMargin: TokenConfig.appearance.spacing.extraSmall / 2 - parent.spacing
            Layout.fillWidth: true
            label: Tr.tr("Normal")
            value: TokenConfig.appearance.fontSize.normal
            from: 8
            to: 40
            stepSize: 1
            showReset: true
            onMoved: v => TokenConfig.appearance.fontSize.normal = v
            onReset: {
                TokenConfig.appearance.fontSize.resetOption("normal");
            }
        }

        StepperRow {
            Layout.topMargin: TokenConfig.appearance.spacing.extraSmall / 2 - parent.spacing
            Layout.fillWidth: true
            label: Tr.tr("Larger")
            value: TokenConfig.appearance.fontSize.larger
            from: 8
            to: 40
            stepSize: 1
            showReset: true
            onMoved: v => TokenConfig.appearance.fontSize.larger = v
            onReset: {
                TokenConfig.appearance.fontSize.resetOption("larger");
            }
        }

        StepperRow {
            Layout.topMargin: TokenConfig.appearance.spacing.extraSmall / 2 - parent.spacing
            Layout.fillWidth: true
            label: Tr.tr("Large")
            value: TokenConfig.appearance.fontSize.large
            from: 10
            to: 48
            stepSize: 1
            showReset: true
            onMoved: v => TokenConfig.appearance.fontSize.large = v
            onReset: {
                TokenConfig.appearance.fontSize.resetOption("large");
            }
        }

        StepperRow {
            Layout.topMargin: TokenConfig.appearance.spacing.extraSmall / 2 - parent.spacing
            last: true
            Layout.fillWidth: true
            label: Tr.tr("Extra Large")
            value: TokenConfig.appearance.fontSize.extraLarge
            from: 12
            to: 72
            stepSize: 1
            showReset: true
            onMoved: v => TokenConfig.appearance.fontSize.extraLarge = v
            onReset: {
                TokenConfig.appearance.fontSize.resetOption("extraLarge");
            }
        }

        SectionHeader {
            text: Tr.tr("Monospace Fonts")
        }

        StepperRow {
            first: true
            Layout.fillWidth: true
            label: Tr.tr("Mono Small")
            value: TokenConfig.appearance.fontSize.monoSmall
            from: 6
            to: 36
            stepSize: 1
            showReset: true
            onMoved: v => TokenConfig.appearance.fontSize.monoSmall = v
            onReset: {
                TokenConfig.appearance.fontSize.resetOption("monoSmall");
            }
        }

        StepperRow {
            Layout.topMargin: TokenConfig.appearance.spacing.extraSmall / 2 - parent.spacing
            Layout.fillWidth: true
            label: Tr.tr("Mono Medium")
            value: TokenConfig.appearance.fontSize.monoMedium
            from: 8
            to: 40
            stepSize: 1
            showReset: true
            onMoved: v => TokenConfig.appearance.fontSize.monoMedium = v
            onReset: {
                TokenConfig.appearance.fontSize.resetOption("monoMedium");
            }
        }

        StepperRow {
            Layout.topMargin: TokenConfig.appearance.spacing.extraSmall / 2 - parent.spacing
            last: true
            Layout.fillWidth: true
            label: Tr.tr("Mono Large")
            value: TokenConfig.appearance.fontSize.monoLarge
            from: 10
            to: 48
            stepSize: 1
            showReset: true
            onMoved: v => TokenConfig.appearance.fontSize.monoLarge = v
            onReset: {
                TokenConfig.appearance.fontSize.resetOption("monoLarge");
            }
        }
    }
}
