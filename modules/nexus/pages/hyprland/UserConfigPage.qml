import QtQuick
import QtQuick.Layouts
import Aether.Config
import Aether.I18n
import qs.components
import qs.services
import qs.modules.nexus.common

PageBase {
    id: root

    title: Tr.tr("User configuration")
    isSubPage: true

    ColumnLayout {
        anchors.centerIn: parent
        spacing: Tokens.padding.extraSmall

        MaterialIcon {
            Layout.alignment: Qt.AlignHCenter
            text: "handyman"
            color: Colours.palette.m3outlineVariant
            fontStyle: Tokens.font.icon.extraLarge
        }

        StyledText {
            Layout.alignment: Qt.AlignHCenter
            text: Tr.tr("Page under construction")
            color: Colours.palette.m3outlineVariant
            font: Tokens.font.title.large
        }

        StyledText {
            Layout.alignment: Qt.AlignHCenter
            text: Tr.tr("This page will be available in a future update.")
            color: Colours.palette.m3outlineVariant
            font: Tokens.font.body.large
        }
    }
}
