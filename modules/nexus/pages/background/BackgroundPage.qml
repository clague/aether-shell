import QtQuick.Layouts
import Caelestia.Config
import qs.modules.nexus.common

PageBase {
    id: root

    title: Tr.tr("Background elements")

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.extraSmall / 2

        NavRow {
            first: true
            icon: "schedule"
            text: Tr.tr("Desktop clock")
            subtext: root.targetConfig.background.desktopClock.enabled ? Tr.tr("Enabled") : Tr.tr("Disabled")
            onClicked: root.nState.openSubPage(1)
        }

        NavRow {
            icon: "lyrics"
            text: Tr.tr("Desktop lyrics")
            subtext: root.targetConfig.background.desktopLyrics.enabled ? Tr.tr("Enabled") : Tr.tr("Disabled")
            onClicked: root.nState.openSubPage(2)
        }

        NavRow {
            icon: "equalizer"
            text: Tr.tr("Background visualiser")
            subtext: root.targetConfig.background.visualiser.enabled ? Tr.tr("Enabled") : Tr.tr("Disabled")
            onClicked: root.nState.openSubPage(3)
        }

        NavRow {
            last: true
            icon: "pets"
            text: Tr.tr("Shimeji characters")
            subtext: root.targetConfig.shimeji.enabled ? Tr.tr("Enabled") : Tr.tr("Disabled")
            onClicked: root.nState.openSubPage(4)
        }
    }
}
