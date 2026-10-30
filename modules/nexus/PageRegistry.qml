pragma Singleton

import QtQuick
import Caelestia.I18n

QtObject {
    id: root

    // The order here must match PageCompRegistry.pageComps
    readonly property list<var> pages: [
        // Appearance
        {
            label: Tr.tr("Wallpaper & style"),
            icon: "palette",
            description: Tr.tr("Wallpaper, colours, themes and desktop elements"),
            category: "appearance",
            mode: "appearance"
        },
        {
            label: Tr.tr("Look & feel"),
            icon: "tune",
            description: Tr.tr("Density, glass, motion, fonts and Hyprland variables"),
            category: "appearance"
        },

        // Desktop
        {
            label: Tr.tr("Panels"),
            icon: "dock_to_bottom",
            description: Tr.tr("Dashboard, taskbar, launcher, sidebar"),
            category: "desktop"
        },
        {
            label: Tr.tr("Apps"),
            icon: "apps",
            description: Tr.tr("Default apps, favourites, hidden apps"),
            category: "desktop"
        },
        {
            label: Tr.tr("Hyprland"),
            icon: "layers",
            description: Tr.tr("Window manager configuration"),
            category: "desktop"
        },

        // Connectivity
        {
            label: Tr.tr("Display"),
            icon: "monitor",
            description: Tr.tr("Output configuration"),
            category: "connectivity"
        },
        {
            label: Tr.tr("Network"),
            icon: "wifi",
            description: Tr.tr("Wi-Fi, ethernet, VPN"),
            category: "connectivity",
            mode: "network"
        },
        {
            label: Tr.tr("Connected devices"),
            icon: "devices_other",
            description: Tr.tr("Bluetooth, pairing"),
            category: "connectivity",
            mode: "bluetooth",
            noFill: true
        },
        {
            label: Tr.tr("Audio"),
            icon: "volume_up",
            description: Tr.tr("App volumes, sound devices"),
            category: "connectivity",
            mode: "audio"
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
            description: Tr.tr("Poll intervals, integrations, lyrics backend"),
            category: "system"
        },
        {
            label: Tr.tr("Power & idle"),
            icon: "power_settings_new",
            description: Tr.tr("Idle timeouts, sleep and screen-off behaviour"),
            category: "system"
        },

        // Advanced
        {
            label: Tr.tr("Shell Tokens"),
            icon: "tune",
            description: Tr.tr("Modify interface spacing, rounding, and sizing"),
            category: "advanced",
            developerOnly: true
        },
        // About
        {
            label: Tr.tr("About"),
            icon: "info",
            description: Tr.tr("System information, preset, credits"),
            category: "about"
        },
    ]
}
