pragma ComponentBehavior: Bound

//@ pragma Env QS_CRASHREPORT_URL=https://github.com/caelestia-dots/shell/issues/new?template=crash.yml
//@ pragma DefaultEnv QS_NO_RELOAD_POPUP=1
//@ pragma DefaultEnv QS_DROP_EXPENSIVE_FONTS=1
//@ pragma DefaultEnv QSG_RENDER_LOOP=threaded
//@ pragma DefaultEnv QT_QUICK_FLICKABLE_WHEEL_DECELERATION=10000

<<<<<<< HEAD
import "modules"
import "modules/drawers"
import "modules/background"
import "modules/shimeji"
import "modules/areapicker"
import "modules/lock"
import "modules/polkit"
=======
>>>>>>> caelestia/main
import QtQuick
import QtQml
import Quickshell
<<<<<<< HEAD
import Quickshell.Services.SystemTray
import Caelestia.Config
import qs.services
import qs.utils
import qs.modules.overview
=======
import Caelestia.Config
import qs.services
import qs.modules.areapicker
import qs.modules.background
import qs.modules.drawers
import qs.modules.lock
import qs.daemons
>>>>>>> caelestia/main

ShellRoot {
    id: root

    // Force service initialization
    property var _arpcInit: DiscordRPC

    property var _gameModeInit: GameMode

    property var _pipInit: PipManager

    property var _systemTrayInit: SystemTray

    settings.watchFiles: true

    Component.onCompleted: {
<<<<<<< HEAD
        Qt.callLater(() => {
            Weather.reload();
            PastafarianCalendar.reload();
        });
=======
        // Force certain singletons to load on shell init instead of lazily
        Notifs;
        Players;
        Brightness;
        Weather.reload();

        if (GlobalConfig.utilities.vpn.enabled)
            VPN;
    }

    FontLoader {
        source: Quickshell.shellPath("assets/google-sans-flex/GoogleSansFlex-VariableFont_GRAD,ROND,opsz,slnt,wdth,wght.ttf")
>>>>>>> caelestia/main
    }

    Binding {
        target: ShellState
        property: "shellRoot"
        value: root
    }

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

    Lock {
        id: lock
    }

<<<<<<< HEAD
    PolkitModule {}

    Variants {
        model: Quickshell.screens.filter(s => GlobalConfig.hybrid.features.shimeji && (GlobalConfig.shimeji?.enabled ?? false) && (GlobalConfig.shimeji?.directory.length ?? 0) > 0 && !Strings.testRegexList(GlobalConfig.shimeji?.excludedScreens ?? [], s.name))

        Shimeji {
            shimejiCount: GlobalConfig.shimeji?.count ?? 1
        }
    }
    Shortcuts {}
    BatteryMonitor {}

=======
    // Daemons
    Shortcuts {}
    BatteryMonitor {}
    GameMode {}
    IdleInhibit {}
>>>>>>> caelestia/main
    IdleMonitors {
        lock: lock
    }

    BluetoothReconnect {}
}
