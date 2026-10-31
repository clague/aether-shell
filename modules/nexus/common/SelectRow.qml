import QtQuick
import QtQuick.Layouts
import Aether.Config
import qs.components
import qs.components.controls
import qs.services
import qs.modules.nexus.common

ConnectedRect {
    id: root

    property alias label: label.text
    property string subtext
    property var configNode
    property string propertyName: ""
    property alias menuItems: splitButton.menuItems
    property alias active: splitButton.active
    property alias fallbackText: splitButton.fallbackText
    property alias fallbackIcon: splitButton.fallbackIcon
    property alias menuOnTop: splitButton.menuOnTop

    property bool disabled: false

    signal selected(item: MenuItem)

    function activate(): void {
        if (root.enabled)
            splitButton.expanded = !splitButton.expanded;
    }

    Layout.fillWidth: true
    enabled: !disabled
    implicitHeight: rowLayout.implicitHeight + rowLayout.anchors.margins * 2
    clip: false
    z: splitButton.expanded ? 1 : 0

    // Focusable like the rest of the rows; Space/Enter open the same menu the button opens.
    activeFocusOnTab: true

    Keys.onSpacePressed: event => {
        root.activate();
        event.accepted = true;
    }

    Keys.onReturnPressed: event => {
        root.activate();
        event.accepted = true;
    }

    Keys.onEnterPressed: event => {
        root.activate();
        event.accepted = true;
    }

    RowLayout {
        id: rowLayout

        anchors.fill: parent
        anchors.margins: Tokens.padding.medium
        anchors.leftMargin: Tokens.padding.largeIncreased
        anchors.rightMargin: Tokens.padding.largeIncreased
        spacing: Tokens.spacing.medium

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0

            RowLayout {
                Layout.fillWidth: true
                spacing: Tokens.spacing.small

                StyledText {
                    id: label

                    font: Tokens.font.body.small
                    elide: Text.ElideRight
                }

                PerMonitorStatusChip {
                    configNode: root.configNode
                    propertyName: root.propertyName
                }

                Item {
                    Layout.fillWidth: true
                }
            }

            StyledText {
                Layout.fillWidth: true
                visible: root.subtext
                text: root.subtext
                color: Colours.palette.m3outline
                font: Tokens.font.label.small
                elide: Text.ElideRight
            }
        }

        SplitButton {
            id: splitButton

            // Opening the menu (by click or by Space) puts focus on the row, so the arrow keys
            // carry on from here.
            onExpandedChanged: {
                if (expanded)
                    root.forceActiveFocus(Qt.MouseFocusReason);
            }

            type: SplitButton.Tonal
            stateLayer.onClicked: splitButton.expanded = !splitButton.expanded
            menu.onItemSelected: item => root.selected(item)
        }
    }
}
