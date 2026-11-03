local scheme = require("scheme.current")
local vars   = require("variables")

hl.config({
    misc = {
        animate_manual_resizes       = vars.animateManualResizes,
        animate_mouse_windowdragging = vars.animateMouseWindowdragging,

        disable_hyprland_logo        = vars.disableHyprlandLogo,
        force_default_wallpaper      = 0,

        on_focus_under_fullscreen    = 2,
        allow_session_lock_restore   = true,
        middle_click_paste           = vars.middleClickPaste,
        focus_on_activate            = vars.focusOnActivate,
        session_lock_xray            = vars.sessionLockXray,

        mouse_move_enables_dpms      = vars.mouseMoveEnablesDpms,
        key_press_enables_dpms       = vars.keyPressEnablesDpms,

        vrr                          = vars.vrr,

        background_color             = "rgb(" .. scheme.surfaceContainer .. ")",
    },

    debug = {
        error_position = 1
    }
})
