pragma ComponentBehavior: Bound

import QtQuick
import qs.components

// The same dialog the polkit agent shows, so a password prompt looks the same whichever program
// asked. It is the polkit window rather than a copy: `agent` accepts anything with the two
// members the dialog uses, and the shim below maps them onto an askpass request.
PolkitDialog {
    id: root

    required property var askpass

    agent: shim
    splitMessages: false
    windowName: "askpass"

    QtObject {
        id: shim

        readonly property bool isActive: root.askpass.active
        readonly property var flow: flowShim
    }

    QtObject {
        id: flowShim

        readonly property string message: root.askpass.current ? root.askpass.current.prompt : ""
        readonly property string supplementaryMessage: ""
        readonly property bool supplementaryIsError: false

        function submit(text: string): void {
            root.askpass.submit(text);
        }

        function cancelAuthenticationRequest(): void {
            root.askpass.cancel();
        }
    }
}
