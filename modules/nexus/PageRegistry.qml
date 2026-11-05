pragma Singleton

import QtQuick
import Aether.I18n

QtObject {
    id: root

    // The order here must match PageCompRegistry.pageComps.
    //
    // Categories are contiguous: the sidebar draws a heading whenever this field changes, so a
    // page that is moved must be moved within its block, not appended somewhere else with the
    // same category.
    readonly property list<var> pages: [
        // Appearance
        {
            label: Tr.tr("Wallpaper & style"),
            icon: "palette",
            description: Tr.tr("Wallpaper, colours, themes and desktop elements"),
            category: "appearance",
            mode: "appearance",
            key: "wallpaper"
        },
        {
            label: Tr.tr("Look & feel"),
            icon: "tune",
            description: Tr.tr("Shell appearance and app fonts"),
            category: "appearance"
        },

        // Desktop
        {
            label: Tr.tr("Panels"),
            icon: "dock_to_bottom",
            description: Tr.tr("Dashboard, taskbar, launcher, sidebar"),
            category: "desktop",
            key: "panels"
        },
        {
            label: Tr.tr("Apps"),
            icon: "apps",
            description: Tr.tr("Default apps, favourites, hidden apps"),
            category: "desktop"
        },

        // Window
        {
            label: Tr.tr("Hyprland"),
            icon: "layers",
            description: Tr.tr("Window manager configuration"),
            category: "window",
            key: "hyprland"
        },

        // Devices
        {
            label: Tr.tr("Display"),
            icon: "monitor",
            description: Tr.tr("Monitors, scaling and brightness"),
            category: "devices"
        },
        {
            label: Tr.tr("Audio"),
            icon: "volume_up",
            description: Tr.tr("Outputs, app volumes and sound effects"),
            category: "devices",
            mode: "audio",
            key: "audio"
        },
        {
            label: Tr.tr("Connected devices"),
            icon: "devices_other",
            description: Tr.tr("Bluetooth, pairing"),
            category: "devices",
            mode: "bluetooth",
            noFill: true
        },
        {
            label: Tr.tr("Network"),
            icon: "wifi",
            description: Tr.tr("Wi-Fi, ethernet, VPN"),
            category: "devices",
            mode: "network"
        },
        {
            label: Tr.tr("Power & idle"),
            icon: "power_settings_new",
            description: Tr.tr("Idle timeouts, sleep and screen-off behaviour"),
            category: "devices"
        },

        // System
        {
            label: Tr.tr("Updates"),
            icon: "update",
            description: Tr.tr("System updates"),
            category: "system"
        },
        {
            label: Tr.tr("Plugins"),
            icon: "extension",
            description: Tr.tr("Manage plugins"),
            category: "system"
        },
        {
            label: Tr.tr("Doctor"),
            icon: "health_and_safety",
            description: Tr.tr("Check Wi-Fi, Bluetooth, audio, displays and services"),
            category: "system"
        },
        {
            label: Tr.tr("Language & region"),
            icon: "globe",
            description: Tr.tr("UI language, weather location, display units"),
            category: "system"
        },
        {
            label: Tr.tr("Services"),
            icon: "build",
            description: Tr.tr("Poll intervals, integrations, media backend"),
            category: "system",
            key: "services"
        },
        {
            label: Tr.tr("Shell Tokens"),
            icon: "tune",
            description: Tr.tr("Modify interface spacing, rounding, and sizing"),
            category: "system",
            developerOnly: true
        },
        {
            label: Tr.tr("About"),
            icon: "info",
            description: Tr.tr("System information, preset, credits"),
            category: "system",
            key: "about"
        },
    ]

    // Sidebar headings. The keys are the `category` values above; anything missing falls back to
    // the raw key rather than an empty heading, so a new category is visible even before it is
    // translated.
    readonly property var categoryLabels: ({
            appearance: Tr.tr("Appearance"),
            desktop: Tr.tr("Desktop"),
            window: Tr.tr("Window"),
            devices: Tr.tr("Devices"),
            system: Tr.tr("System")
        })

    function categoryLabel(category: string): string {
        return root.categoryLabels[category] ?? category;
    }
}
