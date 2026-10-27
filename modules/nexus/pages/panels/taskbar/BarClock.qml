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
<<<<<<< HEAD
            text: qsTr("Background")
            configNode: root.targetConfig.bar.clock
            propertyName: "background"
            checked: root.targetConfig.bar.clock.background
            onToggled: {
                root.targetConfig.bar.clock.background = checked;
            }
        }

        ToggleRow {
            text: qsTr("Show date")
            configNode: root.targetConfig.bar.clock
            propertyName: "showDate"
            checked: root.targetConfig.bar.clock.showDate
            onToggled: {
                root.targetConfig.bar.clock.showDate = checked;
            }
        }

        ToggleRow {
            last: true
            text: qsTr("Show icon")
            configNode: root.targetConfig.bar.clock
            propertyName: "showIcon"
            checked: root.targetConfig.bar.clock.showIcon
            onToggled: {
                root.targetConfig.bar.clock.showIcon = checked;
            }
=======
            text: Tr.trCtx("Background", "taskbar clock: draw a background behind the clock")
            checked: Config.bar.clock.background
            onToggled: GlobalConfig.bar.clock.background = checked
        }

        ToggleRow {
            text: Tr.tr("Show date")
            checked: Config.bar.clock.showDate
            onToggled: GlobalConfig.bar.clock.showDate = checked
        }

        ToggleRow {
            text: Tr.tr("Show icon")
            checked: Config.bar.clock.showIcon
            onToggled: GlobalConfig.bar.clock.showIcon = checked
>>>>>>> caelestia/main
        }

        ToggleRow {
            last: true
            text: Tr.tr("Show seconds")
            checked: Config.bar.clock.showSeconds
            onToggled: GlobalConfig.bar.clock.showSeconds = checked
        }
    }
}
