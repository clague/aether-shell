local vars = require("variables")

-- Themes
hl.env("QT_WAYLAND_DISABLE_WINDOWDECORATION", "1")
hl.env("XCURSOR_THEME", vars.cursorTheme)
hl.env("XCURSOR_SIZE", vars.cursorSize)

-- Toolkit backends
-- QML2_IMPORT_PATH is deliberately not set here: `aether shell` points it at the checkout's
-- build/qml. A hardcoded path in the compositor config only helps one machine and breaks every
-- other checkout.
hl.env("GDK_BACKEND", "wayland,x11")
hl.env("QT_QPA_PLATFORM", "wayland;xcb")
hl.env("SDL_VIDEODRIVER", "wayland,x11")
hl.env("CLUTTER_BACKEND", "wayland")
hl.env("ELECTRON_OZONE_PLATFORM_HINT", "auto")

-- Others
hl.env("_JAVA_AWT_WM_NONREPARENTING", "1")

-- Password prompts and Qt theming, so a default install needs no hand-written exports.
-- aether-askpass is the helper the package and tools/install-cli.sh put on PATH; SSH still
-- uses the terminal when one is attached, and SSH_ASKPASS_REQUIRE=force changes that.
hl.env("SSH_ASKPASS", "aether-askpass")
hl.env("SUDO_ASKPASS", "aether-askpass")
-- The Qt platform theme plugin ships with the shell; Nexus > Look & feel > Qt applications
-- owns the widget style. A checkout needs ./tools/install-qt-theme.sh first.
hl.env("QT_QPA_PLATFORMTHEME", "aether")
