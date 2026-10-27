import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.modules.nexus.common

PageBase {
    id: root

    title: Tr.tr("Shimeji characters")
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
            text: Tr.tr("Enable Shimeji")
            configNode: root.targetConfig.shimeji
            propertyName: "enabled"
            checked: root.targetConfig.shimeji.enabled
            onToggled: {
                root.targetConfig.shimeji.enabled = checked;
            }
        }

        ToggleRow {
            Layout.topMargin: Tokens.spacing.extraSmall / 2 - parent.spacing
            Layout.fillWidth: true
            text: Tr.tr("Auto-hide Shimeji")
            subtext: Tr.tr("Hide Shimeji when a window is open")
            configNode: root.targetConfig.shimeji
            propertyName: "autoHide"
            checked: root.targetConfig.shimeji.autoHide
            onToggled: {
                root.targetConfig.shimeji.autoHide = checked;
            }
            enabled: root.targetConfig.shimeji.enabled
        }

        StepperRow {
            Layout.topMargin: Tokens.spacing.extraSmall / 2 - parent.spacing
            last: true
            Layout.fillWidth: true
            label: Tr.tr("Shimeji count per screen")
            configNode: root.targetConfig.shimeji
            propertyName: "count"
            from: 1
            to: 9999
            stepSize: 1
            value: root.targetConfig.shimeji.count
            onMoved: v => {
                root.targetConfig.shimeji.count = v;
            }
            enabled: root.targetConfig.shimeji.enabled
        }
    }
}
