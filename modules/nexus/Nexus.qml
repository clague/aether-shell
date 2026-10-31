pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Window
import Aether.Blobs
import Aether.Config
import qs.components
import qs.components.controls
import qs.services
import qs.modules.nexus
import qs.modules.nexus.pages.bluetooth

Item {
    id: root

    readonly property NexusState nState: NexusState {
        id: nState

        onClose: root.close()
    }

    property color blobColour: Colours.tPalette.m3surfaceContainerLow

    // True while a text input owns the keyboard, so shortcuts for printable characters can stay
    // out of the way. Qt reports the inner input item for text-field controls.
    readonly property bool textInputFocused: {
        const item = root.Window.window ? root.Window.window.activeFocusItem : null;
        return item instanceof TextInput || item instanceof TextEdit;
    }

    signal close

    // Tokens are per-screen. `targetScreen` is the *config target* and is deliberately empty
    // in Global mode ("applies to all monitors"), but Tokens still needs a real screen: with
    // none, every padding/spacing/font read warns and falls back to the global appearance.
    // The window's own screen supplies the tokens; page configs keep resolving through
    // nState.targetScreen (see PageBase.targetConfig).
    Config.screen: nState.targetScreen.length > 0 ? nState.targetScreen : (Screen.name ?? "")

    // Sized from the screen height, but never wider than the screen (a rotated, portrait display
    // is taller than it is wide, which used to make the window many times wider than the screen)
    implicitWidth: Math.round(implicitHeight * Tokens.sizes.nexus.ratio)
    implicitHeight: Math.round(Math.min(nState.screen.height * Tokens.sizes.nexus.heightMult, nState.screen.width * 0.92 / Tokens.sizes.nexus.ratio))

    // Arrow keys walk the same focus chain Tab uses; see FocusNav. Keys that a focused control
    // consumes for itself (a slider's value, a text field's caret) never reach these handlers.
    Keys.onUpPressed: event => {
        FocusNav.move(Window.window, false);
        event.accepted = true;
    }

    Keys.onDownPressed: event => {
        FocusNav.move(Window.window, true);
        event.accepted = true;
    }

    Keys.onLeftPressed: event => {
        FocusNav.move(Window.window, false);
        event.accepted = true;
    }

    Keys.onRightPressed: event => {
        FocusNav.move(Window.window, true);
        event.accepted = true;
    }

    Behavior on blobColour {
        CAnim {}
    }

    TapHandler {
        onTapped: root.focus = true
    }

    // Browser-style back/forward on the mouse's side buttons. TapHandler reports which button
    // was tapped, so this does not steal the ordinary left click above.
    TapHandler {
        acceptedButtons: Qt.BackButton | Qt.ForwardButton

        onTapped: (eventPoint, button) => {
            if (button === Qt.BackButton)
                nState.goBack();
            else
                nState.goForward();
        }
    }

    BlobGroup {
        id: blobGroup

        smoothing: root.Tokens.rounding.medium
        color: root.blobColour
    }

    BlobInvertedRect {
        anchors.fill: parent
        group: blobGroup
        opacity: root.blobColour.a
        radius: Tokens.rounding.large

        borderLeft: navPane.width + navPane.anchors.margins * 2
        borderRight: Tokens.padding.medium
        borderTop: Tokens.padding.medium
        borderBottom: Tokens.padding.medium
    }

    BlobRect {
        id: windowBtnRect

        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: root.nState.isWindow ? 0 : Tokens.padding.extraSmall

        group: blobGroup
        opacity: root.blobColour.a
        radius: Tokens.rounding.medium

        implicitWidth: windowBtn.implicitWidth + (root.nState.isWindow ? Tokens.padding.extraSmall : Tokens.padding.small) * 2
        implicitHeight: windowBtn.implicitHeight + (root.nState.isWindow ? Tokens.padding.extraSmall : Tokens.padding.small)
    }

    IconButton {
        id: windowBtn

        anchors.centerIn: windowBtnRect
        icon: nState.isWindow ? "close" : "pip"
        type: IconButton.Text
        label.fill: 0
        inactiveOnColour: hovered ? nState.isWindow ? Colours.palette.m3error : Colours.palette.m3primary : Colours.palette.m3onSurfaceVariant
        stateLayer.opacity: 0
        onClicked: {
            if (!nState.isWindow)
                WindowFactory.create();
            root.close();
        }

        label.scale: pressed ? 0.8 : 1
        label.renderType: Text.QtRendering

        Behavior on label.scale {
            Anim {}
        }
    }

    NavPane {
        id: navPane

        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.margins: Tokens.padding.large

        nState: nState
        width: Math.min(Tokens.sizes.nexus.maxNavWidth, Math.round(root.width / 3))
    }

    Pages {
        anchors.left: navPane.right
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.leftMargin: navPane.anchors.margins + anchors.margins
        anchors.margins: Tokens.padding.extraLarge

        visible: !nState.searchOpen
        nState: nState
    }

    SearchResults {
        anchors.left: navPane.right
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.leftMargin: navPane.anchors.margins + anchors.margins
        anchors.margins: Tokens.padding.extraLarge

        visible: nState.searchOpen
        nState: nState
    }

    Shortcut {
        sequence: "Ctrl+F"
        onActivated: nState.focusSearch()
    }

    // Vim/Firefox-style search key. Suppressed while a text field has focus, or it would eat the
    // slash instead of letting the user type it.
    Shortcut {
        sequence: "/"
        enabled: !root.textInputFocused
        onActivated: nState.focusSearch()
    }

    // Keyboard equivalents of the mouse's back/forward buttons.
    Shortcut {
        sequence: "Alt+Left"
        enabled: !root.textInputFocused
        onActivated: nState.goBack()
    }

    Shortcut {
        sequence: "Alt+Right"
        enabled: !root.textInputFocused
        onActivated: nState.goForward()
    }

    // Bluetooth pairing dialog, overlaying the whole Nexus window rather than the pairing
    // page. PageBase takes a single `contentChild`, so it cannot host a sibling overlay,
    // and this is where the dialog can actually cover whatever page is open.
    //
    // The agent's lifetime deliberately follows this Loader; there is no eager load in
    // ServiceLoader. scripts/bt-agent.py calls `RequestDefaultAgent`, taking over as the
    // *system* BlueZ pairing agent, and OP registered it at shell startup while mounting
    // the dialog only on the pairing page -- so a request arriving with that page closed was
    // captured from whatever agent would otherwise have served it, and then left unanswered
    // until BlueZ timed out. Tying registration to the dialog means we only claim the role
    // while something can answer, and otherwise leave the desktop's own agent alone.
    Loader {
        anchors.fill: parent
        z: 100
        active: GlobalConfig.hybrid.features.btAgent

        sourceComponent: BluetoothPairingDialog {}
    }
}
