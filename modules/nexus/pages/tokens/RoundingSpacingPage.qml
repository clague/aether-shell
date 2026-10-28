import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import Caelestia.I18n
import qs.modules.nexus.common

PageBase {
    id: root

    title: Tr.tr("Rounding & Spacing")
    isSubPage: true

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: TokenConfig.appearance.spacing.extraSmall / 2

        SectionHeader {
            first: true
            text: Tr.tr("Corner Rounding")
        }

        StepperRow {
            first: true
            Layout.fillWidth: true
            label: Tr.tr("Extra Small")
            value: TokenConfig.appearance.rounding.extraSmall
            from: 0
            to: 100
            stepSize: 1
            showReset: true
            onMoved: v => TokenConfig.appearance.rounding.extraSmall = v
            onReset: {
                TokenConfig.appearance.rounding.resetOption("extraSmall");
            }        }

        StepperRow {
            Layout.topMargin: TokenConfig.appearance.spacing.extraSmall / 2 - parent.spacing
            Layout.fillWidth: true
            label: Tr.tr("Small")
            value: TokenConfig.appearance.rounding.small
            from: 0
            to: 100
            stepSize: 1
            showReset: true
            onMoved: v => TokenConfig.appearance.rounding.small = v
            onReset: {
                TokenConfig.appearance.rounding.resetOption("small");
            }        }

        StepperRow {
            Layout.topMargin: TokenConfig.appearance.spacing.extraSmall / 2 - parent.spacing
            Layout.fillWidth: true
            label: Tr.tr("Medium")
            value: TokenConfig.appearance.rounding.medium
            from: 0
            to: 100
            stepSize: 1
            showReset: true
            onMoved: v => TokenConfig.appearance.rounding.medium = v
            onReset: {
                TokenConfig.appearance.rounding.resetOption("medium");
            }        }

        StepperRow {
            Layout.topMargin: TokenConfig.appearance.spacing.extraSmall / 2 - parent.spacing
            Layout.fillWidth: true
            label: Tr.tr("Large")
            value: TokenConfig.appearance.rounding.large
            from: 0
            to: 100
            stepSize: 1
            showReset: true
            onMoved: v => TokenConfig.appearance.rounding.large = v
            onReset: {
                TokenConfig.appearance.rounding.resetOption("large");
            }        }

        StepperRow {
            Layout.topMargin: TokenConfig.appearance.spacing.extraSmall / 2 - parent.spacing
            Layout.fillWidth: true
            label: Tr.tr("Large Increased")
            value: TokenConfig.appearance.rounding.largeIncreased
            from: 0
            to: 100
            stepSize: 1
            showReset: true
            onMoved: v => TokenConfig.appearance.rounding.largeIncreased = v
            onReset: {
                TokenConfig.appearance.rounding.resetOption("largeIncreased");
            }        }

        StepperRow {
            Layout.topMargin: TokenConfig.appearance.spacing.extraSmall / 2 - parent.spacing
            Layout.fillWidth: true
            label: Tr.tr("Extra Large")
            value: TokenConfig.appearance.rounding.extraLarge
            from: 0
            to: 100
            stepSize: 1
            showReset: true
            onMoved: v => TokenConfig.appearance.rounding.extraLarge = v
            onReset: {
                TokenConfig.appearance.rounding.resetOption("extraLarge");
            }        }

        StepperRow {
            Layout.topMargin: TokenConfig.appearance.spacing.extraSmall / 2 - parent.spacing
            Layout.fillWidth: true
            label: Tr.tr("Extra Large Increased")
            value: TokenConfig.appearance.rounding.extraLargeIncreased
            from: 0
            to: 100
            stepSize: 1
            showReset: true
            onMoved: v => TokenConfig.appearance.rounding.extraLargeIncreased = v
            onReset: {
                TokenConfig.appearance.rounding.resetOption("extraLargeIncreased");
            }        }

        StepperRow {
            Layout.topMargin: TokenConfig.appearance.spacing.extraSmall / 2 - parent.spacing
            last: true
            Layout.fillWidth: true
            label: Tr.tr("Extra Extra Large")
            value: TokenConfig.appearance.rounding.extraExtraLarge
            from: 0
            to: 150
            stepSize: 2
            showReset: true
            onMoved: v => TokenConfig.appearance.rounding.extraExtraLarge = v
            onReset: {
                TokenConfig.appearance.rounding.resetOption("extraExtraLarge");
            }        }

        SectionHeader {
            text: Tr.tr("Layout Spacing")
        }

        StepperRow {
            first: true
            Layout.fillWidth: true
            label: Tr.tr("Extra Small")
            value: TokenConfig.appearance.spacing.extraSmall
            from: 0
            to: 100
            stepSize: 1
            showReset: true
            onMoved: v => TokenConfig.appearance.spacing.extraSmall = v
            onReset: {
                TokenConfig.appearance.spacing.resetOption("extraSmall");
            }        }

        StepperRow {
            Layout.topMargin: TokenConfig.appearance.spacing.extraSmall / 2 - parent.spacing
            Layout.fillWidth: true
            label: Tr.tr("Small")
            value: TokenConfig.appearance.spacing.small
            from: 0
            to: 100
            stepSize: 1
            showReset: true
            onMoved: v => TokenConfig.appearance.spacing.small = v
            onReset: {
                TokenConfig.appearance.spacing.resetOption("small");
            }        }

        StepperRow {
            Layout.topMargin: TokenConfig.appearance.spacing.extraSmall / 2 - parent.spacing
            Layout.fillWidth: true
            label: Tr.tr("Medium")
            value: TokenConfig.appearance.spacing.medium
            from: 0
            to: 100
            stepSize: 1
            showReset: true
            onMoved: v => TokenConfig.appearance.spacing.medium = v
            onReset: {
                TokenConfig.appearance.spacing.resetOption("medium");
            }        }

        StepperRow {
            Layout.topMargin: TokenConfig.appearance.spacing.extraSmall / 2 - parent.spacing
            Layout.fillWidth: true
            label: Tr.tr("Large")
            value: TokenConfig.appearance.spacing.large
            from: 0
            to: 100
            stepSize: 1
            showReset: true
            onMoved: v => TokenConfig.appearance.spacing.large = v
            onReset: {
                TokenConfig.appearance.spacing.resetOption("large");
            }        }

        StepperRow {
            Layout.topMargin: TokenConfig.appearance.spacing.extraSmall / 2 - parent.spacing
            Layout.fillWidth: true
            label: Tr.tr("Large Increased")
            value: TokenConfig.appearance.spacing.largeIncreased
            from: 0
            to: 100
            stepSize: 1
            showReset: true
            onMoved: v => TokenConfig.appearance.spacing.largeIncreased = v
            onReset: {
                TokenConfig.appearance.spacing.resetOption("largeIncreased");
            }        }

        StepperRow {
            Layout.topMargin: TokenConfig.appearance.spacing.extraSmall / 2 - parent.spacing
            Layout.fillWidth: true
            label: Tr.tr("Extra Large")
            value: TokenConfig.appearance.spacing.extraLarge
            from: 0
            to: 100
            stepSize: 1
            showReset: true
            onMoved: v => TokenConfig.appearance.spacing.extraLarge = v
            onReset: {
                TokenConfig.appearance.spacing.resetOption("extraLarge");
            }        }

        StepperRow {
            Layout.topMargin: TokenConfig.appearance.spacing.extraSmall / 2 - parent.spacing
            Layout.fillWidth: true
            label: Tr.tr("Extra Large Increased")
            value: TokenConfig.appearance.spacing.extraLargeIncreased
            from: 0
            to: 100
            stepSize: 1
            showReset: true
            onMoved: v => TokenConfig.appearance.spacing.extraLargeIncreased = v
            onReset: {
                TokenConfig.appearance.spacing.resetOption("extraLargeIncreased");
            }        }

        StepperRow {
            Layout.topMargin: TokenConfig.appearance.spacing.extraSmall / 2 - parent.spacing
            last: true
            Layout.fillWidth: true
            label: Tr.tr("Extra Extra Large")
            value: TokenConfig.appearance.spacing.extraExtraLarge
            from: 0
            to: 150
            stepSize: 2
            showReset: true
            onMoved: v => TokenConfig.appearance.spacing.extraExtraLarge = v
            onReset: {
                TokenConfig.appearance.spacing.resetOption("extraExtraLarge");
            }        }

        SectionHeader {
            text: Tr.tr("Inner Padding")
        }

        StepperRow {
            first: true
            Layout.fillWidth: true
            label: Tr.tr("Extra Small")
            value: TokenConfig.appearance.padding.extraSmall
            from: 0
            to: 100
            stepSize: 1
            showReset: true
            onMoved: v => TokenConfig.appearance.padding.extraSmall = v
            onReset: {
                TokenConfig.appearance.padding.resetOption("extraSmall");
            }        }

        StepperRow {
            Layout.topMargin: TokenConfig.appearance.spacing.extraSmall / 2 - parent.spacing
            Layout.fillWidth: true
            label: Tr.tr("Small")
            value: TokenConfig.appearance.padding.small
            from: 0
            to: 100
            stepSize: 1
            showReset: true
            onMoved: v => TokenConfig.appearance.padding.small = v
            onReset: {
                TokenConfig.appearance.padding.resetOption("small");
            }        }

        StepperRow {
            Layout.topMargin: TokenConfig.appearance.spacing.extraSmall / 2 - parent.spacing
            Layout.fillWidth: true
            label: Tr.tr("Medium")
            value: TokenConfig.appearance.padding.medium
            from: 0
            to: 100
            stepSize: 1
            showReset: true
            onMoved: v => TokenConfig.appearance.padding.medium = v
            onReset: {
                TokenConfig.appearance.padding.resetOption("medium");
            }        }

        StepperRow {
            Layout.topMargin: TokenConfig.appearance.spacing.extraSmall / 2 - parent.spacing
            Layout.fillWidth: true
            label: Tr.tr("Large")
            value: TokenConfig.appearance.padding.large
            from: 0
            to: 100
            stepSize: 1
            showReset: true
            onMoved: v => TokenConfig.appearance.padding.large = v
            onReset: {
                TokenConfig.appearance.padding.resetOption("large");
            }        }

        StepperRow {
            Layout.topMargin: TokenConfig.appearance.spacing.extraSmall / 2 - parent.spacing
            Layout.fillWidth: true
            label: Tr.tr("Large Increased")
            value: TokenConfig.appearance.padding.largeIncreased
            from: 0
            to: 100
            stepSize: 1
            showReset: true
            onMoved: v => TokenConfig.appearance.padding.largeIncreased = v
            onReset: {
                TokenConfig.appearance.padding.resetOption("largeIncreased");
            }        }

        StepperRow {
            Layout.topMargin: TokenConfig.appearance.spacing.extraSmall / 2 - parent.spacing
            Layout.fillWidth: true
            label: Tr.tr("Extra Large")
            value: TokenConfig.appearance.padding.extraLarge
            from: 0
            to: 100
            stepSize: 1
            showReset: true
            onMoved: v => TokenConfig.appearance.padding.extraLarge = v
            onReset: {
                TokenConfig.appearance.padding.resetOption("extraLarge");
            }        }

        StepperRow {
            Layout.topMargin: TokenConfig.appearance.spacing.extraSmall / 2 - parent.spacing
            Layout.fillWidth: true
            label: Tr.tr("Extra Large Increased")
            value: TokenConfig.appearance.padding.extraLargeIncreased
            from: 0
            to: 100
            stepSize: 1
            showReset: true
            onMoved: v => TokenConfig.appearance.padding.extraLargeIncreased = v
            onReset: {
                TokenConfig.appearance.padding.resetOption("extraLargeIncreased");
            }        }

        StepperRow {
            Layout.topMargin: TokenConfig.appearance.spacing.extraSmall / 2 - parent.spacing
            last: true
            Layout.fillWidth: true
            label: Tr.tr("Extra Extra Large")
            value: TokenConfig.appearance.padding.extraExtraLarge
            from: 0
            to: 150
            stepSize: 2
            showReset: true
            onMoved: v => TokenConfig.appearance.padding.extraExtraLarge = v
            onReset: {
                TokenConfig.appearance.padding.resetOption("extraExtraLarge");
            }        }
    }
}
