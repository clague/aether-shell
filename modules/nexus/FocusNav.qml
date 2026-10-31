pragma Singleton

import QtQuick

// Keyboard focus traversal for the settings UI.
//
// Qt already keeps a focus chain per window: every item with activeFocusOnTab is visited by
// Tab/Shift+Tab, and QQuickItem::nextItemInFocusChain() walks the same chain. Arrow-key
// navigation is expressed through that chain, so no page or row has to map keys by hand.
QtObject {
    // `win` is passed in because QQuickItem does not expose its window to QML; call sites have
    // it as the Window.window attached property.
    function move(win: var, forward: bool): void {
        if (!win)
            return;

        const current = win.activeFocusItem;
        if (current) {
            const next = current.nextItemInFocusChain(forward);
            if (next)
                next.forceActiveFocus(forward ? Qt.TabFocusReason : Qt.BacktabFocusReason);
            return;
        }

        // Nothing is focused yet (for example right after the window opened): start at the first
        // focusable control so the arrows work without tabbing in first.
        const first = firstFocusable(win.contentItem, forward);
        if (first)
            first.forceActiveFocus(forward ? Qt.TabFocusReason : Qt.BacktabFocusReason);
    }

    // Depth-first walk of the visual tree for the first item that can take focus.
    function firstFocusable(item: Item, forward: bool): Item {
        if (!item || !item.visible || !item.enabled)
            return null;

        if (item.activeFocusOnTab)
            return item;

        const children = item.children;
        if (forward) {
            for (let i = 0; i < children.length; i++) {
                const hit = firstFocusable(children[i], forward);
                if (hit)
                    return hit;
            }
            return null;
        }

        for (let i = children.length - 1; i >= 0; i--) {
            const hit = firstFocusable(children[i], forward);
            if (hit)
                return hit;
        }
        return null;
    }
}
