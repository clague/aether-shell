import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.services
import qs.modules.nexus.common

PageBase {
    id: root

    title: Tr.tr("Quick Share")

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.extraSmall / 2

        SectionHeader {
            first: true
            text: Tr.tr("Startup")
        }

        ToggleRow {
            first: true
            last: true
            text: Tr.tr("Auto-start on launch")
            subtext: Tr.tr("Enable Quick Share when the shell starts")
            configNode: root.targetConfig.services
            propertyName: "quickShareAutoStart"
            checked: root.targetConfig.services.quickShareAutoStart
            onToggled: {
                root.targetConfig.services.quickShareAutoStart = checked;
            }
        }

        SectionHeader {
            text: Tr.tr("Status")
        }

        ToggleRow {
            first: true
            last: true
            text: Tr.tr("Enable Quick Share")
            subtext: QuickShare.isEnabled ? Tr.tr("Discoverable by nearby devices") : Tr.tr("Disabled")
            checked: QuickShare.isEnabled
            onToggled: {
                QuickShare.setEnabled(checked);
                QuickShare.setVisible(checked);
            }
        }
    }
}
