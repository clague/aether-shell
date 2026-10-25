import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import Caelestia.I18n
import qs.components.controls
import qs.modules.nexus.common

PageBase {
    id: root

    // Ordered to match config::HybridPreset (Recommended, Midnight, Op).
    readonly property list<MenuItem> presetItems: [
        MenuItem {
            text: Tr.tr("Recommended")
            icon: "recommend"
        },
        MenuItem {
            text: "MiDnight"
            icon: "dark_mode"
        },
        MenuItem {
            text: "OP"
            icon: "bolt"
        }
    ]

    // Ordered to match config::HybridVariant (Midnight, Op). Indexed by ordinal, so a new
    // enumerator must be appended in both places -- see T47.
    readonly property list<MenuItem> variantItems: [
        MenuItem {
            text: Tr.tr("MiDnight")
        },
        MenuItem {
            text: Tr.tr("OP")
        }
    ]

    title: Tr.tr("Hybrid")

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.extraSmall / 2

        SectionHeader {
            first: true
            text: Tr.tr("Preset")
        }

        SelectRow {
            first: true
            last: true
            label: Tr.tr("Preset")
            subtext: Tr.tr("A starting set of features. Anything you change below stays changed.")
            configNode: GlobalConfig.hybrid
            propertyName: "preset"
            menuItems: root.presetItems
            active: root.presetItems[GlobalConfig.hybrid.preset]
            onSelected: item => {
                GlobalConfig.hybrid.preset = root.presetItems.indexOf(item);
            }
        }

        // ------------------------------------------------------------- panels

        SectionHeader {
            text: Tr.tr("Panels")
        }

        ToggleRow {
            first: true
            text: Tr.tr("Dock")
            subtext: Tr.tr("A separate dock window with pinned and running apps")
            configNode: GlobalConfig.hybrid.features
            propertyName: "dock"
            checked: GlobalConfig.hybrid.features.dock
            onToggled: GlobalConfig.hybrid.features.dock = checked
        }

        ToggleRow {
            last: true
            text: Tr.tr("Overview")
            subtext: Tr.tr("Workspace overview with window thumbnails")
            configNode: GlobalConfig.hybrid.features
            propertyName: "overview"
            checked: GlobalConfig.hybrid.features.overview
            onToggled: GlobalConfig.hybrid.features.overview = checked
        }

        // ------------------------------------------------------------ launcher

        SectionHeader {
            text: Tr.tr("Launcher")
        }

        ToggleRow {
            first: true
            text: Tr.tr("Clipboard history")
            subtext: Tr.tr("Search and paste from the launcher")
            configNode: GlobalConfig.hybrid.features
            propertyName: "clipboard"
            checked: GlobalConfig.hybrid.features.clipboard
            onToggled: GlobalConfig.hybrid.features.clipboard = checked
        }

        ToggleRow {
            text: Tr.tr("Emoji picker")
            subtext: Tr.tr("Search emoji from the launcher")
            configNode: GlobalConfig.hybrid.features
            propertyName: "emojiPicker"
            checked: GlobalConfig.hybrid.features.emojiPicker
            onToggled: GlobalConfig.hybrid.features.emojiPicker = checked
        }

        ToggleRow {
            text: Tr.tr("Window switcher")
            subtext: Tr.tr("Switch windows from the launcher")
            configNode: GlobalConfig.hybrid.features
            propertyName: "windowSwitcher"
            checked: GlobalConfig.hybrid.features.windowSwitcher
            onToggled: GlobalConfig.hybrid.features.windowSwitcher = checked
        }

        ToggleRow {
            text: Tr.tr("Keybind viewer")
            subtext: Tr.tr("Browse Hyprland keybinds from the launcher")
            configNode: GlobalConfig.hybrid.features
            propertyName: "keybindViewer"
            checked: GlobalConfig.hybrid.features.keybindViewer
            onToggled: GlobalConfig.hybrid.features.keybindViewer = checked
        }

        ToggleRow {
            text: Tr.tr("Video wallpapers")
            subtext: Tr.tr("Animated wallpapers, paused when nothing can see them")
            configNode: GlobalConfig.hybrid.features
            propertyName: "videoWallpaper"
            checked: GlobalConfig.hybrid.features.videoWallpaper
            onToggled: GlobalConfig.hybrid.features.videoWallpaper = checked
        }

        ToggleRow {
            text: Tr.tr("Wallhaven")
            subtext: Tr.tr("Browse and set wallpapers from wallhaven.cc")
            configNode: GlobalConfig.hybrid.features
            propertyName: "wallhaven"
            checked: GlobalConfig.hybrid.features.wallhaven
            onToggled: GlobalConfig.hybrid.features.wallhaven = checked
        }

        ToggleRow {
            text: Tr.tr("Floating lyrics")
            subtext: Tr.tr("Show synced lyrics on the desktop")
            configNode: GlobalConfig.hybrid.features
            propertyName: "floatingLyrics"
            checked: GlobalConfig.hybrid.features.floatingLyrics
            onToggled: GlobalConfig.hybrid.features.floatingLyrics = checked
        }

        ToggleRow {
            text: Tr.tr("Theme packs")
            subtext: Tr.tr("Swap wallpaper and shell artwork as a named set")
            configNode: GlobalConfig.hybrid.features
            propertyName: "themeManager"
            checked: GlobalConfig.hybrid.features.themeManager
            onToggled: GlobalConfig.hybrid.features.themeManager = checked
        }

        ToggleRow {
            text: Tr.tr("Pomodoro timer")
            subtext: Tr.tr("A focus/break timer next to the dashboard clock")
            configNode: GlobalConfig.hybrid.features
            propertyName: "pomodoro"
            checked: GlobalConfig.hybrid.features.pomodoro
            onToggled: GlobalConfig.hybrid.features.pomodoro = checked
        }

        ToggleRow {
            text: Tr.tr("Scratchpad")
            subtext: Tr.tr("A keyboard-driven notes overlay with tags")
            configNode: GlobalConfig.hybrid.features
            propertyName: "quicknote"
            checked: GlobalConfig.hybrid.features.quicknote
            onToggled: GlobalConfig.hybrid.features.quicknote = checked
        }

        ToggleRow {
            text: Tr.tr("Background doctor")
            subtext: Tr.tr("Run the health checks periodically and toast when something changes")
            configNode: GlobalConfig.hybrid.features
            propertyName: "doctorWatchdog"
            checked: GlobalConfig.hybrid.features.doctorWatchdog
            onToggled: GlobalConfig.hybrid.features.doctorWatchdog = checked
        }

        ToggleRow {
            last: true
            text: Tr.tr("Confirm power actions on the lock screen")
            subtext: Tr.tr("Ask before shutdown, reboot or logout from the lock screen")
            configNode: GlobalConfig.hybrid.features
            propertyName: "lockPowerConfirm"
            checked: GlobalConfig.hybrid.features.lockPowerConfirm
            onToggled: GlobalConfig.hybrid.features.lockPowerConfirm = checked
        }

        SectionHeader {
            text: Tr.tr("Network")
        }

        ToggleRow {
            first: true
            text: Tr.tr("Hotspot")
            subtext: Tr.tr("Share this machine's connection as a Wi-Fi access point")
            configNode: GlobalConfig.hybrid.features
            propertyName: "hotspot"
            checked: GlobalConfig.hybrid.features.hotspot
            onToggled: GlobalConfig.hybrid.features.hotspot = checked
        }

        ToggleRow {
            last: true
            text: Tr.tr("Bluetooth pairing agent")
            subtext: Tr.tr("Answer pairing requests from other devices. Takes effect on restart")
            configNode: GlobalConfig.hybrid.features
            propertyName: "btAgent"
            checked: GlobalConfig.hybrid.features.btAgent
            onToggled: GlobalConfig.hybrid.features.btAgent = checked
        }

        SectionHeader {
            text: Tr.tr("For fun")
        }

        ToggleRow {
            first: true
            text: Tr.tr("Shimeji")
            subtext: Tr.tr("Desktop pets that wander across your screens")
            configNode: GlobalConfig.hybrid.features
            propertyName: "shimeji"
            checked: GlobalConfig.hybrid.features.shimeji
            onToggled: GlobalConfig.hybrid.features.shimeji = checked
        }

        ToggleRow {
            text: Tr.tr("Bad Apple")
            subtext: Tr.tr("You know what this is")
            configNode: GlobalConfig.hybrid.features
            propertyName: "badApple"
            checked: GlobalConfig.hybrid.features.badApple
            onToggled: GlobalConfig.hybrid.features.badApple = checked
        }

        ToggleRow {
            last: true
            text: Tr.tr("Dino game")
            subtext: Tr.tr("The Chrome runner, in the notification dock")
            configNode: GlobalConfig.hybrid.features
            propertyName: "dino"
            checked: GlobalConfig.hybrid.features.dino
            onToggled: GlobalConfig.hybrid.features.dino = checked
        }

        // ------------------------------------------------------------ variants

        SectionHeader {
            text: Tr.tr("Variants")
        }

        // Only sites that genuinely have two implementations appear here. A selector for one
        // that does not would visibly do nothing, which is worse than its absence.
        //
        // `desktopClock` and `colours` were declared alongside these and are now gone. OP's
        // DesktopClock.qml is byte-identical to upstream's, so there was never a second clock
        // to select between, and its Colours.qml change is +52/-2 on a *service*, which D5 says
        // is merged rather than dual-implemented. `lockCentre` is still declared and still
        // absent here, because OP genuinely has a second one -- but its PasswordInput refers to
        // PatternGrid eight times, so importing it means importing the lock-screen bypass that
        // D10 and T3 block. It waits on Phase 8.
        SelectRow {
            first: true
            label: Tr.tr("Audio popout")
            subtext: Tr.tr("Which fork's audio panel the bar opens")
            configNode: GlobalConfig.hybrid.variants
            propertyName: "audioPopout"
            menuItems: root.variantItems
            active: root.variantItems[GlobalConfig.hybrid.variants.audioPopout === HybridVariant.Op ? 1 : 0]
            onSelected: item => {
                GlobalConfig.hybrid.variants.audioPopout = root.variantItems.indexOf(item) === 1 ? HybridVariant.Op : HybridVariant.Midnight;
            }
        }

        SelectRow {
            label: Tr.tr("Workspace overview")
            subtext: Tr.tr("MiDnight's drawer, or OP's carousel and window grid")
            configNode: GlobalConfig.hybrid.variants
            propertyName: "overview"
            menuItems: root.variantItems
            active: root.variantItems[GlobalConfig.hybrid.variants.overview === HybridVariant.Op ? 1 : 0]
            onSelected: item => {
                GlobalConfig.hybrid.variants.overview = root.variantItems.indexOf(item) === 1 ? HybridVariant.Op : HybridVariant.Midnight;
            }
        }

        SelectRow {
            last: true
            label: Tr.tr("Dock")
            subtext: Tr.tr("MiDnight's bar section, or OP's auto-hiding panel")
            configNode: GlobalConfig.hybrid.variants
            propertyName: "dock"
            menuItems: root.variantItems
            active: root.variantItems[GlobalConfig.hybrid.variants.dock === HybridVariant.Op ? 1 : 0]
            onSelected: item => {
                GlobalConfig.hybrid.variants.dock = root.variantItems.indexOf(item) === 1 ? HybridVariant.Op : HybridVariant.Midnight;
            }
        }
    }
}
