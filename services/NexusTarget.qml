pragma Singleton

import QtQuick

// The Nexus instance that last had keyboard focus. Global shortcuts (the mouse's back/forward
// buttons, which Qt only delivers for some button codes) act on it; null while no settings
// window is focused, so pressing those buttons elsewhere does not navigate a background window.
QtObject {
    property var state: null
}
