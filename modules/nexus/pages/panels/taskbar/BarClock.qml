pragma ComponentBehavior: Bound

import QtQuick.Layouts
import Caelestia.Config
import Caelestia.I18n
import qs.modules.nexus.common

PageBase {
    id: root

    title: Tr.tr("Clock")
    isSubPage: true

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.extraSmall / 2

        ToggleRow {
            first: true
            text: Tr.tr("Background")
            configNode: root.targetConfig.bar.clock
            propertyName: "background"
            checked: root.targetConfig.bar.clock.background
            onToggled: {
                root.targetConfig.bar.clock.background = checked;
            }
        }

        ToggleRow {
            text: Tr.tr("Show date")
            configNode: root.targetConfig.bar.clock
            propertyName: "showDate"
            checked: root.targetConfig.bar.clock.showDate
            onToggled: {
                root.targetConfig.bar.clock.showDate = checked;
            }
        }

        ToggleRow {
            last: true
            text: Tr.tr("Show icon")
            configNode: root.targetConfig.bar.clock
            propertyName: "showIcon"
            checked: root.targetConfig.bar.clock.showIcon
            onToggled: {
                root.targetConfig.bar.clock.showIcon = checked;
            }        }

        ToggleRow {
            last: true
            text: Tr.tr("Show seconds")
            checked: Config.bar.clock.showSeconds
            onToggled: GlobalConfig.bar.clock.showSeconds = checked
        }
    }
}
