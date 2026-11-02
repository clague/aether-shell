pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Services.Polkit 0.1
import qs.components
import qs.services

Scope {
    id: root

    PolkitAgent {
        id: agent
        // PolkitAgent handles dbus registration automatically.
    }

    PolkitDialog {
        agent: agent
        screen: Quickshell.screens[0]
    }

    // The same prompt for programs with no terminal of their own, driven by scripts/askpass.sh
    // (SSH_ASKPASS / SUDO_ASKPASS). It shares the module because both answer the same question.
    AskpassDialog {
        askpass: Askpass
        screen: Quickshell.screens[0]
    }
}
