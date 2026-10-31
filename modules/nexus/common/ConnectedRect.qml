import QtQuick
import QtQuick.Window
import Aether.Config
import qs.components
import qs.services

StyledRect {
    id: root

    property bool first
    property bool last

    // Rows that host a focusable child (slider, text field, button) get the ring automatically.
    // Rows whose control is not a child of them -- ToggleRow wraps a Switch -- bind this to that
    // control's focus instead.
    property bool showFocusRing: false

    // True while keyboard focus is on this row or anywhere inside it. Follows the window's active
    // focus item, which Qt updates for Tab, arrow-key and mouse focus alike.
    readonly property bool keyboardFocused: {
        let item = root.Window.window ? root.Window.window.activeFocusItem : null;
        while (item) {
            if (item === root)
                return true;
            item = item.parent;
        }
        return false;
    }

    color: Colours.tPalette.m3surfaceContainer
    topLeftRadius: first ? Tokens.rounding.extraLarge : Tokens.rounding.extraSmall
    topRightRadius: first ? Tokens.rounding.extraLarge : Tokens.rounding.extraSmall
    bottomLeftRadius: last ? Tokens.rounding.extraLarge : Tokens.rounding.extraSmall
    bottomRightRadius: last ? Tokens.rounding.extraLarge : Tokens.rounding.extraSmall

    StyledRect {
        anchors.fill: parent
        z: 1

        visible: root.showFocusRing || root.keyboardFocused
        color: "transparent"
        border.width: 2
        border.color: Colours.palette.m3primary

        topLeftRadius: root.topLeftRadius
        topRightRadius: root.topRightRadius
        bottomLeftRadius: root.bottomLeftRadius
        bottomRightRadius: root.bottomRightRadius
    }
}
