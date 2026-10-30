pragma ComponentBehavior: Bound

//@ pragma Env QS_CRASHREPORT_URL=https://github.com/caelestia-dots/shell/issues/new?template=crash.yml
//@ pragma DefaultEnv QS_NO_RELOAD_POPUP=1
//@ pragma DefaultEnv QS_DROP_EXPENSIVE_FONTS=1
//@ pragma DefaultEnv QSG_RENDER_LOOP=threaded
//@ pragma DefaultEnv QT_QUICK_FLICKABLE_WHEEL_DECELERATION=10000
// Input methods: Hyprland does not forward text-input-v3 to wlr-layer-shell
// surfaces, so an IME cannot reach the launcher/sidebar without Qt's own IM plugin
// (which talks to fcitx/ibus over D-Bus). Only set when the user has not chosen.
//@ pragma DefaultEnv QT_IM_MODULE=fcitx

import QtQuick
import QtQml
import Quickshell
import Quickshell.Services.SystemTray
import Caelestia.Config
import qs.services
import qs.utils
import qs.modules
import qs.modules.areapicker
import qs.modules.background
import qs.modules.displays
import qs.modules.drawers
import qs.modules.lock
import qs.modules.overview
import qs.modules.polkit
import qs.modules.quicknote
import qs.modules.shimeji
import qs.daemons

ShellRoot {
    id: root

    // Force service initialization
    property var _arpcInit: DiscordRPC

    property var _gameModeInit: GameMode

    property var _pipInit: PipManager

    property var _systemTrayInit: SystemTray

    settings.watchFiles: true

    Component.onCompleted: {
        // Force certain singletons to load on shell init instead of lazily
        Notifs;
        Players;
        Brightness;
        Weather.reload();

        if (GlobalConfig.utilities.vpn.enabled)
            VPN;

        // MiDnight's calendar needs its events fetched once at startup.
        PastafarianCalendar.reload();
    }

    Binding {
        target: ShellState
        property: "shellRoot"
        value: root
    }

    GSFLoader {}
    ServiceLoader {}

    // Modules
    Background {}
    DesktopLyricsOverlay {}
    BadAppleOverlay {}

    Drawers {}

    // OP's overview, the second implementation of hybrid.variants.overview. Unlike MiDnight's
    // -- which is a panel inside modules/drawers and woven into the alias, region and
    // deform-matrix graph there (T1) -- this one is a self-contained Scope with its own
    // per-screen visibility, so hosting it is a Loader and nothing else.
    //
    // Both are gated on hybrid.features.overview, which is the on/off switch; the variant only
    // decides which of the two that switch opens.
    Loader {
        active: GlobalConfig.hybrid.features.overview && GlobalConfig.hybrid.variants.overview === HybridVariant.Op

        sourceComponent: Overview {}
    }
    AreaPicker {}
    // OP's scratchpad overlay. Its window is lazy per screen; the feature gate decides
    // whether the scope exists at all, the per-screen ScreenState.quicknote whether it opens.
    Loader {
        active: GlobalConfig.hybrid.features.quicknote

        sourceComponent: QuickNote {}
    }

    DisplayConfirm {}
    DisplayChooser {}
    DisplayProfileAsk {}
    Lock {
        id: lock
    }

    PolkitModule {}

    Variants {
        model: Quickshell.screens.filter(s => GlobalConfig.hybrid.features.shimeji && (GlobalConfig.shimeji?.enabled ?? false) && (GlobalConfig.shimeji?.directory.length ?? 0) > 0 && !Strings.testRegexList(GlobalConfig.shimeji?.excludedScreens ?? [], s.name))

        Shimeji {
            shimejiCount: GlobalConfig.shimeji?.count ?? 1
        }
    }

    // Daemons
    Shortcuts {}
    BatteryMonitor {}
    IdleInhibit {}
    IdleMonitors {
        lock: lock
    }

    BluetoothReconnect {}
}
