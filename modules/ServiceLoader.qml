import QtQuick
import Quickshell
import Caelestia.Config
import qs.services
import qs.daemons

Scope {
    Component.onCompleted: {
        // Force certain singletons to load on shell init instead of lazily.
        // IdleInhibit is mirrored by upstream's daemons/IdleInhibit connection, which owns
        // its IdleInhibitor child -- this can only force the singletons' own creation.

        GameMode;
        Notifs;
        Players;
        Brightness;
        Weather.reload();

        if (GlobalConfig.hybrid.variants.dock === HybridVariant.Op)
            DockPins;;

        if (GlobalConfig.utilities.vpn.enabled)
            VPN;
    }
}
