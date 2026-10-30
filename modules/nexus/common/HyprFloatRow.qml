pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.services
import qs.modules.nexus.common

// A text row that only accepts a number, bound to one key of ~/.config/caelestia/hypr-vars.lua.
// Used for values Hyprland reads as a float, such as the touchpad scroll factor.
ConnectedRect {
    id: root

    property string label
    property string subtext
    property string varKey

    Layout.fillWidth: true
    implicitHeight: contentRow.implicitHeight + Tokens.padding.medium * 2

    RowLayout {
        id: contentRow

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        anchors.leftMargin: Tokens.padding.largeIncreased
        anchors.rightMargin: Tokens.padding.medium
        spacing: Tokens.spacing.medium

        Column {
            Layout.fillWidth: true
            spacing: 0

            RowLayout {
                width: parent.width
                spacing: Tokens.spacing.small

                StyledText {
                    text: root.label
                    font: Tokens.font.body.small
                    elide: Text.ElideRight
                }

                IconButton {
                    icon: "delete"
                    type: IconButton.Text
                    font: Tokens.font.icon.small
                    visible: HyprVars.vars[root.varKey] !== undefined
                    onClicked: HyprVars.deleteVar(root.varKey)
                }

                Item {
                    Layout.fillWidth: true
                }
            }

            StyledText {
                text: root.subtext
                visible: text !== ""
                font: Tokens.font.label.small
                color: Colours.palette.m3outline
                elide: Text.ElideRight
            }
        }

        StyledTextField {
            Layout.preferredWidth: 350
            Layout.alignment: Qt.AlignVCenter
            text: HyprVars.vars[root.varKey] !== undefined ? String(HyprVars.vars[root.varKey]) : ""
            placeholderText: HyprVars.defaults[root.varKey] !== undefined ? String(HyprVars.defaults[root.varKey]) : ""
            onEditingFinished: {
                if (text === "")
                    HyprVars.deleteVar(root.varKey);
                else if (!isNaN(parseFloat(text)))
                    HyprVars.saveVar(root.varKey, parseFloat(text));
            }
        }
    }
}
