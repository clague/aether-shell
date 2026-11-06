pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Aether.Config
import Aether.I18n
import qs.components
import qs.components.controls
import qs.services
import qs.modules.nexus.common

// A free-form text row bound to one key of ~/.config/aether/hypr-vars.lua. Clearing the field
// removes the override instead of writing an empty string.
ConnectedRect {
    id: root

    property string label
    property string subtext
    property string varKey

    // Scheme-derived defaults are Lua expressions such as `rgba(" .. scheme.primary .. "e6)`.
    // Showing that verbatim in the empty field is noise; the row is an override, so say where
    // the value comes from instead.
    readonly property string defaultText: {
        const value = HyprVars.defaults[root.varKey];
        if (value === undefined)
            return "";
        const text = String(value);
        return text.includes("scheme.") || text.includes("..") ? Tr.tr("From theme") : text;
    }

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
            placeholderText: root.defaultText
            onEditingFinished: {
                if (text === "")
                    HyprVars.deleteVar(root.varKey);
                else
                    HyprVars.saveVar(root.varKey, text);
            }
        }
    }
}
