import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import Caelestia.I18n
import qs.components.controls
import qs.modules.nexus.common

PageBase {
    id: root

    title: Tr.tr("Background visualiser")
    isSubPage: true

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.extraSmall / 2

        SectionHeader {
            first: true
            text: Tr.tr("General")
        }

        ToggleRow {
            first: true
            Layout.fillWidth: true
            text: Tr.tr("Enable background visualiser")
            configNode: root.targetConfig.background.visualiser
            propertyName: "enabled"
            checked: root.targetConfig.background.visualiser.enabled
            onToggled: {
                root.targetConfig.background.visualiser.enabled = checked;
            }
        }

        ToggleRow {
            Layout.topMargin: Tokens.spacing.extraSmall / 2 - parent.spacing
            Layout.fillWidth: true
            text: Tr.tr("Auto-hide visualiser")
            subtext: Tr.tr("Hide visualiser when a window is open")
            configNode: root.targetConfig.background.visualiser
            propertyName: "autoHide"
            checked: root.targetConfig.background.visualiser.autoHide
            onToggled: {
                root.targetConfig.background.visualiser.autoHide = checked;
            }
            enabled: root.targetConfig.background.visualiser.enabled
        }

        ToggleRow {
            Layout.topMargin: Tokens.spacing.extraSmall / 2 - parent.spacing
            Layout.fillWidth: true
            text: Tr.tr("Blur background")
            subtext: Tr.tr("Blur the wallpaper behind the visualiser")
            configNode: root.targetConfig.background.visualiser
            propertyName: "blur"
            checked: root.targetConfig.background.visualiser.blur
            onToggled: {
                root.targetConfig.background.visualiser.blur = checked;
            }
            enabled: root.targetConfig.background.visualiser.enabled
        }

        SelectRow {
            Layout.topMargin: Tokens.spacing.extraSmall / 2 - parent.spacing
            last: true
            Layout.fillWidth: true
            label: qsTr("Renderer")
            configNode: root.targetConfig.background.visualiser
            propertyName: "renderer"
            menuItems: [
                MenuItem {
                    text: qsTr("GPU (Shader)")
                },
                MenuItem {
                    text: qsTr("CPU (QPainter)")
                }
            ]
            active: root.targetConfig.background.visualiser.renderer === "cpu" ? menuItems[1] : menuItems[0]
            onSelected: item => {
                root.targetConfig.background.visualiser.renderer = item === menuItems[1] ? "cpu" : "gpu";
                root.targetConfig.save();
            }
            enabled: root.targetConfig.background.visualiser.enabled
        }

        SectionHeader {
            text: Tr.tr("Appearance")
        }

        SliderRow {
            first: true
            Layout.fillWidth: true
            label: Tr.tr("Rounding")
            configNode: root.targetConfig.background.visualiser
            propertyName: "rounding"
            value: root.targetConfig.background.visualiser.rounding / 10.0
            valueLabel: (value * 10.0).toFixed(1)
            onMoved: v => {
                root.targetConfig.background.visualiser.rounding = v * 10.0;
            }
        }

        SliderRow {
            Layout.topMargin: Tokens.spacing.extraSmall / 2 - parent.spacing
            Layout.fillWidth: true
            label: Tr.tr("Spacing")
            configNode: root.targetConfig.background.visualiser
            propertyName: "spacing"
            value: root.targetConfig.background.visualiser.spacing / 10.0
            valueLabel: (value * 10.0).toFixed(1)
            onMoved: v => {
                root.targetConfig.background.visualiser.spacing = v * 10.0;
            }
        }

        StepperRow {
            Layout.topMargin: Tokens.spacing.extraSmall / 2 - parent.spacing
            last: true
            Layout.fillWidth: true
            label: Tr.tr("Visualiser bars")
            subtext: Tr.tr("Number of bars in the audio visualisers")
            configNode: root.targetConfig.services
            propertyName: "visualiserBars"
            value: root.targetConfig.services.visualiserBars
            from: 10
            to: 120
            stepSize: 2
            onMoved: v => {
                root.targetConfig.services.visualiserBars = v;
            }
        }
    }
}
