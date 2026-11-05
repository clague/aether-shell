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
