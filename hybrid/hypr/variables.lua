local scheme = require("scheme.current")

return {
    ------------------
    ---- HYPRLAND ----
    ------------------

    -- Apps
    terminal                   = "foot",
    browser                    = "firefox",
    editor                     = "codium",
    fileExplorer               = "thunar",
    audioSettings              = "pwvucontrol",

    -- Keyboard
    kbLayout                   = "us",
    kbVariant                  = "",
    kbOptions                  = "",
    repeatRate                 = 35,
    repeatDelay                = 250,
    numlockByDefault           = false,

    -- Mouse
    followMouse                = 1,
    sensitivity                = 0.0,
    accelProfile               = "flat",
    naturalScroll              = false,
    middleButtonEmulation      = false,

    -- Touchpad
    touchpadDisableTyping      = true,
    touchpadScrollFactor       = 0.3,
    touchpadNaturalScroll      = true,

    -- Gestures
    gestureFingers             = 3,
    workspaceSwipeFingers      = 4,
    gestureFingersMore         = 4,
    workspaceSwipeDistance     = 700,
    workspaceSwipeCancelRatio  = 0.15,
    workspaceSwipeMinSpeed     = 5,
    workspaceSwipeDirLock      = true,
    workspaceSwipeDirLockThreshold = 10,
    workspaceSwipeCreateNew    = true,

    -- Blur
    blurEnabled                = true,
    blurSpecialWs              = false,
    blurPopups                 = true,
    blurInputMethods           = true,
    blurSize                   = 8,
    blurPasses                 = 2,
    blurXray                   = false,

    -- Shadow
    shadowEnabled              = true,
    shadowRange                = 15,
    shadowRenderPower          = 4,
    shadowColour               = "rgba(" .. scheme.inversePrimary .. "10)",

    -- Layout
    layout                     = "dwindle",
    scrollingFullscreenOnOneColumn = true,
    scrollingFocusFitMethod    = 1,
    scrollingColumnWidth       = 0.5,
    scrollingFollowFocus       = true,
    scrollingFollowMinVisible  = 0.0,
    scrollingExplicitColumnWidths = "0.35, 0.5, 0.65, 1.0",

    -- Window behaviour
    focusOnClose               = false,
    onFocusUnderFullscreen     = 2,
    allowSessionLockRestore    = true,

    -- Gaps
    workspaceGaps              = 20,
    windowGapsIn               = 5,
    windowGapsOut              = 10,
    singleWindowGapsOut        = 20,

    -- Window behaviour
    allowTearing               = false,
    resizeOnBorder             = false,

    -- Dwindle layout
    preserveSplit              = true,
    smartSplit                 = false,
    smartResizing              = true,

    -- Window styling
    windowOpacity              = 0.95,
    windowRounding             = 15,
    windowRoundingPower        = 2,
    windowBorderSize           = 1,
    activeWindowBorderColour   = "rgba(" .. scheme.primary .. "e6)",
    inactiveWindowBorderColour = "rgba(" .. scheme.onSurfaceVariant .. "11)",
    dimInactive                = false,
    dimStrength                = 0.2,

    -- Window groups
    groupbarFontFamily          = "JetBrains Mono NF",
    groupbarFontSize            = 15,
    groupbarGradients           = true,
    groupbarGradientRoundOnlyEdges = false,
    groupbarGradientRounding    = 5,
    groupbarHeight              = 25,
    groupbarIndicatorHeight     = 0,
    groupbarGapsIn              = 3,
    groupbarGapsOut             = 3,
    groupbarTextColour          = "rgb(" .. scheme.onPrimary .. ")",
    groupbarActiveColour        = "rgba(" .. scheme.primary .. "d4)",
    groupbarInactiveColour      = "rgba(" .. scheme.outline .. "d4)",
    groupbarLockedActiveColour  = "rgba(" .. scheme.primary .. "d4)",
    groupbarLockedInactiveColour = "rgba(" .. scheme.secondary .. "d4)",

    -- Glass (written by the shell from Settings)
    overviewBlur               = false,
    solidTextWindows           = false,
    solidTextClasses           = "zen|firefox|chromium|google-chrome|brave-browser|code|code-oss|obsidian|org\\.pwmt\\.zathura|org\\.gnome\\.Evince|libreoffice.*",

    -- Motion (written by the shell from Settings)
    animSpeed                  = 1,
    animMatchShell             = false,
    animSpatialCurve           = "0.38, 1.21, 0.22, 1",
    animEffectsCurve           = "0.34, 0.88, 0.34, 1",
    animSpatialSpeed           = 5,
    animEffectsSpeed           = 3,

    -- Misc
    volumeStep                 = 10,
    volumeMax                  = 100,
    forceDefaultWallpaper      = 0,
    cursorTheme                = "sweet-cursors",
    cursorSize                 = 24,
    sleepGestureCmd            = "systemctl suspend-then-hibernate",
    specialWsCloseAny          = true,
    vrr                        = 0,
    disableHyprlandLogo        = true,
    mouseMoveEnablesDpms       = true,
    keyPressEnablesDpms        = true,
    focusOnActivate            = true,
    middleClickPaste           = false,
    sessionLockXray            = true,
    animateManualResizes       = false,
    animateMouseWindowdragging = false,

    ------------------
    ---- KEYBINDS ----
    ------------------

    -- Modifier only, the actual binds will be mod + 0-9. These should be strings and not arrays.
    kbGoToWs                   = "SUPER",
    kbGoToWsGroup              = "CTRL + SUPER",
    kbMoveWinToWs              = "SUPER + ALT",
    kbMoveWinToWsSilent        = "SUPER + SHIFT",
    kbMoveWinToWsGroup         = "CTRL + SUPER + ALT",

    -- All the following binds can be either an array of binds to bind multiple keys, or a single string.

    -- Workspaces
    kbMoveWinToWsSpecial       = { "SUPER + ALT + S", "CTRL + SUPER + SHIFT + Up" },
    kbMoveWinFromWsSpecial     = "CTRL + SUPER + SHIFT + Down",
    kbMoveWinToWsNext          = { "SUPER + ALT + mouse_down", "SUPER + ALT + Page_Down", "CTRL + SUPER + SHIFT + Right" },
    kbMoveWinToWsPrev          = { "SUPER + ALT + mouse_up", "SUPER + ALT + Page_Up", "CTRL + SUPER + SHIFT + Left" },
    kbNextWs                   = { "SUPER + mouse_down", "CTRL + SUPER + Right", "SUPER + Page_Down" },
    kbPrevWs                   = { "SUPER + mouse_up", "CTRL + SUPER + Left", "SUPER + Page_Up" },
    kbNextWsGroup              = "CTRL + SUPER + mouse_down",
    kbPrevWsGroup              = "CTRL + SUPER + mouse_up",

    -- Window Group
    kbWindowCycleNext          = "ALT + TAB",
    kbWindowCyclePrev          = "SHIFT + ALT + TAB",
    kbWindowGroupCycleNext     = "CTRL + ALT + TAB",
    kbWindowGroupCyclePrev     = "CTRL + SHIFT + ALT + TAB",
    kbUngroup                  = "SUPER + U",
    kbToggleGroup              = "SUPER + Comma",
    kbGroupLockActive          = "SUPER + SHIFT + Comma",

    -- Window Actions
    kbWindowDecreaseWidth      = { "SUPER + Minus", "SUPER + ALT + Left" },
    kbWindowIncreaseWidth      = { "SUPER + Equal", "SUPER + ALT + Right" },
    kbWindowDecreaseHeight     = { "SUPER + SHIFT + Minus", "SUPER + ALT + Up" },
    kbWindowIncreaseHeight     = { "SUPER + SHIFT + Equal", "SUPER + ALT + Down" },

    kbMoveWindow               = "SUPER + Z",
    kbResizeWindow             = "SUPER + X",
    kbCenterWindow             = "CTRL + SUPER + Backslash",
    kbNormalizeWindow          = "CTRL + SUPER + ALT + Backslash",
    kbWindowPip                = "SUPER + ALT + Backslash",
    kbPinWindow                = "SUPER + P",
    kbWindowFullscreen         = "SUPER + F",
    kbWindowBorderedFullscreen = "SUPER + ALT + F",
    kbToggleWindowFloating     = "SUPER + ALT + Space",
    kbCloseWindow              = "SUPER + Q",

    -- Special workspaces toggles
    kbSpecialWs                = "SUPER + S",
    kbSystemMonitorWs          = "CTRL + SHIFT + Escape",
    kbMusicWs                  = "SUPER + M",
    kbCommunicationWs          = "SUPER + D",
    kbTodoWs                   = "SUPER + R",

    -- Apps
    kbTerminal                 = "SUPER + T",
    kbBrowser                  = "SUPER + W",
    kbEditor                   = "SUPER + C",
    kbFileExplorer             = "SUPER + E",
    kbAudioSettings            = "CTRL + ALT + V",

    -- Utilities
    kbScreenshot               = "Print",
    kbScreenshotFreeze         = "SUPER + SHIFT + S",
    kbScreenshotRegion         = "SUPER + SHIFT + ALT + S",
    kbRecord                   = "CTRL + ALT + R",
    kbRecordSound              = "SUPER + ALT + R",
    kbRecordRegion             = "SUPER + SHIFT + ALT + R",
    kbColorPicker              = "SUPER + SHIFT + C",

    -- Media
    kbMediaToggle              = "CTRL + SUPER + Space",
    kbMediaNext                = "CTRL + SUPER + Equal",
    kbMediaPrev                = "CTRL + SUPER + Minus",
    kbMediaStop                = "CTRL + SUPER + Backspace",
    kbVolumeMute               = "SUPER + SHIFT + M",

    -- Misc
    kbLauncher                 = "SUPER + SUPER_L",
    kbSession                  = "CTRL + ALT + Delete",
    kbShowSidebar              = "SUPER + N",
    kbClearNotifs              = "CTRL + ALT + C",
    kbShowPanels               = "SUPER + K",
    kbLock                     = "SUPER + L",
    kbRestoreLock              = "SUPER + ALT + L",
    kbSleep                    = "SUPER + SHIFT + L",

    -- Clipboard and emoji picker
    kbClipboard                = "SUPER + V",
    kbClipboardDel             = "SUPER + ALT + V",
    kbClipboardPasteLatest     = "CTRL + SHIFT + ALT + V",
    kbEmoji                    = "SUPER + Period",
}
