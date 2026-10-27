import QtQuick
import Caelestia.I18n
import qs.modules.dashboard
import qs.modules.nexus.common

PageBase {
    title: Tr.tr("Wallhaven")
    isSubPage: true
    scrollable: false

    WallhavenTab {
        anchors.fill: parent
    }
}
