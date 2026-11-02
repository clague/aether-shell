pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell.Wayland
import Aether.Config
import Aether.I18n
import qs.components
import qs.components.containers
import qs.components.controls
import qs.services

// The prompt scripts/askpass.sh drives (SSH_ASKPASS / SUDO_ASKPASS). A layer-shell overlay rather
// than a floating window: the program asking has no window of its own to sit above, and a layer
// surface is the only thing guaranteed to be visible from wherever the request comes.
StyledWindow {
    id: root

    required property var askpass

    readonly property var request: askpass.current

    name: "askpass"

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: root.visible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    visible: root.request !== null

    anchors.top: true
    anchors.bottom: true
    anchors.left: true
    anchors.right: true

    color: "transparent"

    // A queued request becomes current when the previous one is answered: start from an empty
    // field with the keyboard already on it.
    onVisibleChanged: {
        if (visible) {
            passwordField.text = "";
            passwordField.forceActiveFocus();
        }
    }

    Rectangle {
        anchors.fill: parent
        color: Qt.alpha(Colours.palette.m3scrim, 0.4)
    }

    StyledRect {
        id: card

        anchors.centerIn: parent
        implicitWidth: Math.min(420, root.width - Tokens.padding.extraLarge * 2)
        implicitHeight: cardContent.implicitHeight + Tokens.padding.extraLarge * 2
        radius: Tokens.rounding.extraLarge
        color: Colours.tPalette.m3surfaceContainerHigh

        ColumnLayout {
            id: cardContent

            anchors.left: parent.left
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            anchors.margins: Tokens.padding.extraLarge
            spacing: Tokens.spacing.medium

            MaterialIcon {
                Layout.alignment: Qt.AlignHCenter
                text: "key"
                fontStyle: Tokens.font.icon.builders.extraLarge.scale(2).build()
                color: Colours.palette.m3primary
            }

            StyledText {
                Layout.alignment: Qt.AlignHCenter
                text: Tr.tr("Authentication required")
                font: Tokens.font.title.medium
            }

            StyledText {
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.WordWrap
                text: root.request ? root.request.prompt : ""
                color: Colours.palette.m3onSurfaceVariant
                font: Tokens.font.body.small
            }

            StyledTextField {
                id: passwordField

                Layout.fillWidth: true
                placeholderText: Tr.tr("Password")
                echoMode: TextInput.Password
                inputMethodHints: Qt.ImhNoAutoUppercase | Qt.ImhNoPredictiveText | Qt.ImhSensitiveData

                onAccepted: root.askpass.submit(text)
                Keys.onEscapePressed: root.askpass.cancel()
            }

            RowLayout {
                Layout.alignment: Qt.AlignRight
                spacing: Tokens.spacing.small

                IconTextButton {
                    text: Tr.tr("Cancel")
                    type: TextButton.Text
                    onClicked: root.askpass.cancel()
                }

                IconTextButton {
                    text: Tr.tr("Unlock")
                    icon: "lock_open"
                    type: TextButton.Filled
                    enabled: passwordField.text.length > 0
                    onClicked: root.askpass.submit(passwordField.text)
                }
            }
        }
    }

    Connections {
        function onCurrentChanged(): void {
            passwordField.text = "";
            passwordField.forceActiveFocus();
        }

        target: root.askpass
    }
}
