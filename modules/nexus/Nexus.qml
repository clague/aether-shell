pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Window
import Aether
import Aether.Blobs
import Aether.Config
import qs.components
import qs.components.controls
import qs.services
import qs.utils
import qs.modules.nexus
import qs.modules.nexus.common
import qs.modules.nexus.pages.bluetooth

Item {
    id: root

    readonly property NexusState nState: NexusState {
        id: nState

        onClose: root.close()
    }

    property color blobColour: Colours.tPalette.m3surfaceContainerLow

    readonly property Item focusedItem: root.Window.window ? root.Window.window.activeFocusItem : null

    // Sidebar width. -1 keeps the automatic ratio; dragging the divider stores an explicit width.
    readonly property real navWidthMin: 200
    readonly property real navWidthMax: Math.max(navWidthMin, Math.min(Tokens.sizes.nexus.maxNavWidth, Math.round(root.width * 0.6)))
    property real navWidthOverride: -1
    // Last width actually written, so the debounce timer and the release handler cannot write
    // the same value twice.
    property int savedNavWidth: -1
    readonly property string navStatePath: `${Paths.state}/nexus-nav.json`
    readonly property real navWidth: {
        const auto = Math.max(root.navWidthMin, Math.min(root.navWidthMax, Math.round(root.width / 3)));
        return root.navWidthOverride < 0 ? auto : Math.max(root.navWidthMin, Math.min(root.navWidthMax, root.navWidthOverride));
    }

    // True while a text input owns the keyboard, so shortcuts for printable characters can stay
    // out of the way. Qt reports the inner input item for text-field controls.
    readonly property bool textInputFocused: {
        const item = root.Window.window ? root.Window.window.activeFocusItem : null;
        return item instanceof TextInput || item instanceof TextEdit;
    }

    signal close

    function loadNavWidth(): void {
        // readFile() logs a warning for a missing path, and the smoke matrix treats warnings
        // as failures; a fresh state dir simply has no saved width yet.
        if (!CUtils.fileExists(root.navStatePath))
            return;
        const content = CUtils.readFile(root.navStatePath);
        if (!content)
            return;
        try {
            const data = JSON.parse(content);
            if (typeof data.navWidth === "number") {
                root.navWidthOverride = data.navWidth;
                root.savedNavWidth = Math.round(data.navWidth);
            }
        } catch (e) {
            console.warn("[nexus] could not read the saved nav width:", e);
        }
    }

    function saveNavWidth(): void {
        if (root.navWidthOverride <= 0)
            return;
        const width = Math.round(root.navWidthOverride);
        if (width === root.savedNavWidth)
            return;
        if (!CUtils.writeFile(root.navStatePath, JSON.stringify({
            navWidth: width
        }))) {
            console.warn("[nexus] could not save the nav width");
            return;
        }
        root.savedNavWidth = width;
    }

    function isInside(item: Item, container: Item): bool {
        let node = item;
        while (node) {
            if (node === container)
                return true;
            node = node.parent;
        }
        return false;
    }

    // Walks the focus chain, or starts in the sidebar when only the window root holds focus
    // (right after opening), so the arrows work before the first click.
    function moveFocus(forward: bool): bool {
        const item = root.focusedItem;
        if (!item || item === root)
            return FocusNav.focusFirstIn(navPane, forward);
        FocusNav.move(root.Window.window, forward);
        return true;
    }

    // The window's initial focus item, so key events have somewhere to go before the first
    // click. Qt hands it active focus when the window is activated; children take over as soon
    // as the user clicks or tabs into them.
    focus: true

    // Global shortcuts need to know which settings window a back/forward press belongs to.
    // Keys only reach these handlers through the focused item, so the window has to hand the
    // root focus when it opens (or when it is re-activated with nothing focused); without this
    // the arrows did nothing until the first click.
    onNavWidthOverrideChanged: {
        if (root.navWidthOverride > 0)
            navSaveTimer.restart();
    }

    Window.onActiveChanged: {
        if (Window.active) {
            NexusTarget.state = nState;
            if (!Window.activeFocusItem)
                root.forceActiveFocus(Qt.TabFocusReason);
        } else if (NexusTarget.state === nState) {
            NexusTarget.state = null;
        }
    }

    Component.onCompleted: {
        root.loadNavWidth();
        if (Window.active && !Window.activeFocusItem)
            root.forceActiveFocus(Qt.TabFocusReason);
    }

    Component.onDestruction: {
        root.saveNavWidth();
        if (NexusTarget.state === nState)
            NexusTarget.state = null;
    }

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
        if (nState.easterEgg)
            return;
        event.accepted = root.moveFocus(false);
    }

    Keys.onDownPressed: event => {
        if (nState.easterEgg)
            return;
        event.accepted = root.moveFocus(true);
    }

    // Left/right switch between the panes rather than walking the flat focus chain: the sidebar
    // is navigation, the right-hand side is the page. A focused control that uses the arrows
    // itself (slider, stepper, text field) consumes the key before it reaches here.
    Keys.onLeftPressed: event => {
        if (nState.easterEgg)
            return;
        if (root.isInside(root.focusedItem, pages))
            event.accepted = navPane.focusPageRow(nState.currentPageIdx);
    }

    Keys.onRightPressed: event => {
        if (nState.easterEgg)
            return;
        if (!root.focusedItem || root.focusedItem === root || root.isInside(root.focusedItem, navPane))
            event.accepted = FocusNav.focusFirstIn(pages);
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

        // A click that drags the mouse by a pixel or two is still a tap for these buttons; the
        // default DragThreshold policy drops exactly the presses people make while moving.
        gesturePolicy: TapHandler.ReleaseWithinBounds

        onTapped: (eventPoint, button) => {
            if (button === Qt.BackButton)
                nState.goBack();
            else
                nState.goForward();
        }
    }

    Timer {
        id: navSaveTimer

        interval: 300
        onTriggered: root.saveNavWidth()
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
        width: root.navWidth
    }

    // Drag the divider between the navigation pane and the pages. The nav keeps its automatic
    // ratio until the first drag, then remembers the explicit width for this window.
    Rectangle {
        id: navResizeHandle

        anchors.top: parent.top
        anchors.bottom: parent.bottom
        // The whole gap between the nav and the page content drags: a 10px strip floating in the
        // middle of it was impossible to find once the old pill stopped marking it.
        x: navPane.x + navPane.width - 4
        width: Math.max(16, pages.x - x)
        z: 5
        color: "transparent"

        // A line only while the divider is hovered or dragged. It marks the edge without looking
        // like a scrollbar, which is what the old always-on pill was mistaken for.
        Rectangle {
            anchors.right: parent.right
            anchors.rightMargin: parent.width - 4
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            width: 1
            color: Colours.palette.m3primary
            opacity: navResizeHover.hovered || navResizeDrag.active ? 0.6 : 0

            Behavior on opacity {
                CAnim {}
            }
        }

        HoverHandler {
            id: navResizeHover
        }

        DragHandler {
            id: navResizeDrag

            property real startWidth: 0

            target: null
            cursorShape: Qt.SplitHCursor

            onActiveChanged: {
                if (active)
                    startWidth = root.navWidth;
                else
                    root.saveNavWidth();
            }

            onTranslationChanged: root.navWidthOverride = Math.max(root.navWidthMin, Math.min(root.navWidthMax, startWidth + translation.x))
        }
    }

    Pages {
        id: pages

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
        enabled: !nState.easterEgg
        onActivated: nState.focusSearch()
    }

    // Vim/Firefox-style search key. Suppressed while a text field has focus, or it would eat the
    // slash instead of letting the user type it.
    Shortcut {
        sequence: "/"
        enabled: !root.textInputFocused && !nState.easterEgg
        onActivated: nState.focusSearch()
    }

    // Keyboard equivalents of the mouse's back/forward buttons.
    Shortcut {
        sequence: "Alt+Left"
        enabled: !root.textInputFocused && !nState.easterEgg
        onActivated: nState.goBack()
    }

    Shortcut {
        sequence: "Alt+Right"
        enabled: !root.textInputFocused && !nState.easterEgg
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

    // The About page's easter egg. Hosted here for the same reason as the pairing dialog:
    // it has to cover the pages and their flickable, not live inside one.
    AetherAttunement {
        anchors.fill: parent
        z: 200
        open: root.nState.easterEgg
        onClose: root.nState.easterEgg = false
    }
}
