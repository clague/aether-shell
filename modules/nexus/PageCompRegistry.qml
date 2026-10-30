pragma Singleton

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import Caelestia.I18n
import qs.components
import qs.services
import qs.modules.nexus.common
import qs.modules.nexus.pages
import qs.modules.nexus.pages.apps
import qs.modules.nexus.pages.audio
import qs.modules.nexus.pages.background
import qs.modules.nexus.pages.bluetooth
import qs.modules.nexus.pages.hyprland
import qs.modules.nexus.pages.network
import qs.modules.nexus.pages.panels
import qs.modules.nexus.pages.services
import qs.modules.nexus.pages.tokens
import qs.modules.nexus.pages.wallandstyle
import qs.modules.nexus.pages.panels.taskbar

QtObject {
    id: root

    readonly property list<Component> pageComps: [
        // Appearance
        Component {
            // Wallpaper & style
            StackPage {
                Component {
                    WallpaperAndStyle {}
                }
                Component {
                    WallpaperSelect {}
                }
                Component {
                    WallpaperCategory {}
                }
                Component {
                    ColourSelect {}
                }
                Component {
                    WallhavenPage {}
                }
                Component {
                    WallpaperEnginePage {}
                }
                Component {
                    ThemeSelect {}
                }
                Component {
                    DesktopClockPage {}
                }
                Component {
                    DesktopLyricsPage {}
                }
                Component {
                    VisualiserPage {}
                }
                Component {
                    ShimejiPage {}
                }
            }
        },
        Component {
            // Look & feel
            StackPage {
                Component {
                    LookAndFeelPage {}
                }
                Component {
                    HyprAppearancePage {}
                }
            }
        },
        // Desktop
        Component {
            // Panels
            StackPage {
                Component {
                    PanelsPage {}
                }
                Component {
                    DashboardPanel {}
                }
                Component {
                    TaskbarPanel {}
                }
                Component {
                    LauncherPanel {}
                }
                Component {
                    SidebarPanel {}
                }
                Component {
                    UtilitiesPanel {}
                }
                Component {
                    OsdPanel {}
                }
                Component {
                    OverviewPanel {}
                }
                Component {
                    DockPanel {}
                }

                // Taskbar component sub-pages
                Component {
                    BarComponents {}
                }
                Component {
                    BarWorkspaces {}
                }
                Component {
                    BarActiveWindow {}
                }
                Component {
                    BarTray {}
                }
                Component {
                    BarStatusIcons {}
                }
                Component {
                    BarClock {}
                }
                Component {
                    BarDock {}
                }
                Component {
                    BarGithub {}
                }
                Component {
                    BarSpotify {}
                }
                Component {
                    ScratchpadPanel {}
                }
            }
        },
        Component {
            // Apps
            StackPage {
                Component {
                    AppsPage {}
                }
                Component {
                    AllApps {}
                }
                Component {
                    AppInfo {}
                }
            }
        },
        Component {
            // Hyprland
            StackPage {
                Component {
                    HyprlandPage {}
                }
                Component {
                    HyprVariablesPage {}
                }
                Component {
                    HyprKeybindsPage {}
                }
                Component {
                    UserConfigPage {}
                }
            }
        },
        // Connectivity
        Component {
            // Display
            StackPage {
                Component {
                    DisplayPage {}
                }
            }
        },
        Component {
            // Network
            StackPage {
                Component {
                    NetworkPage {}
                }
                Component {
                    EthernetDetailPage {}
                }
                Component {
                    AddNetworkPage {}
                }
                Component {
                    NetworkDetailPage {}
                }
                Component {
                    AddVpnPage {}
                }
                Component {
                    AllNetworksPage {}
                }
                Component {
                    SavedNetworksPage {}
                }
                Component {
                    HotspotPage {}
                }
            }
        },
        Component {
            // Bluetooth
            StackPage {
                Component {
                    BluetoothPage {}
                }
                Component {
                    BtDeviceInfo {}
                }
                Component {
                    BluetoothPairing {}
                }
            }
        },
        Component {
            // Audio
            StackPage {
                Component {
                    AudioPage {}
                }
                Component {
                    AppVolumes {}
                }
            }
        },
        // System
        Component {
            // Updates
            PlaceholderComp {}
        },
        Component {
            // Plugins
            PlaceholderComp {}
        },
        Component {
            // Doctor
            StackPage {
                Component {
                    DoctorPage {}
                }
            }
        },
        Component {
            // Language & region
            StackPage {
                Component {
                    LanguageAndRegion {}
                }
            }
        },
        Component {
            // Services
            StackPage {
                Component {
                    ServicesPage {}
                }
                Component {
                    NotificationsPage {}
                }
                Component {
                    GameModePage {}
                }
                Component {
                    GameModeTargetsPage {}
                }
                Component {
                    ArpcPage {}
                }
                Component {
                    PipPage {}
                }
                Component {
                    QuickSharePage {}
                }
            }
        },
        Component {
            // Power & idle
            StackPage {
                Component {
                    PowerIdlePage {}
                }
            }
        },
        // Advanced
        Component {
            // Shell Tokens
            StackPage {
                Component {
                    TokensPage {}
                }
                Component {
                    RoundingSpacingPage {}
                }
                Component {
                    FontSizesPage {}
                }
                Component {
                    BarDashboardPage {}
                }
                Component {
                    WindowLockPage {}
                }
                Component {
                    ShellElementsPage {}
                }
            }
        },
        Component {
            // Hybrid
            StackPage {
                Component {
                    HybridPage {}
                }
            }
        },
        // About
        Component {
            StackPage {
                Component {
                    AboutPage {}
                }
            }
        }
    ]

    readonly property Component placeholderComp: Component {
        PlaceholderComp {}
    }

    component PlaceholderComp: Item {
        property NexusState nState // To avoid the warning from non-existent property

        ColumnLayout {
            anchors.centerIn: parent
            spacing: Tokens.padding.extraSmall

            MaterialIcon {
                Layout.alignment: Qt.AlignHCenter
                text: "handyman"
                color: Colours.palette.m3outlineVariant
                fontStyle: Tokens.font.icon.extraLarge
            }

            StyledText {
                Layout.alignment: Qt.AlignHCenter
                text: Tr.tr("Page under construction")
                color: Colours.palette.m3outlineVariant
                font: Tokens.font.title.large
            }

            StyledText {
                Layout.alignment: Qt.AlignHCenter
                text: Tr.tr("This page will be available in a future update.")
                color: Colours.palette.m3outlineVariant
                font: Tokens.font.body.large
            }
        }
    }
}
