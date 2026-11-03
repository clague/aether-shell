local vars = require("variables")

hl.config({
    input = {
        kb_layout               = vars.kbLayout,
        kb_variant              = vars.kbVariant,
        kb_options              = vars.kbOptions,
        numlock_by_default      = vars.numlockByDefault,
        repeat_delay            = vars.repeatDelay,
        repeat_rate             = vars.repeatRate,
        focus_on_close          = 1,

        follow_mouse            = vars.followMouse,
        sensitivity             = vars.sensitivity,
        accel_profile           = vars.accelProfile,
        natural_scroll          = vars.naturalScroll,

        touchpad                = {
            natural_scroll          = vars.touchpadNaturalScroll,
            disable_while_typing    = vars.touchpadDisableTyping,
            scroll_factor           = vars.touchpadScrollFactor,
            middle_button_emulation = vars.middleButtonEmulation,
        },
    },

    binds = {
        scroll_event_delay = 0,
    },

    cursor = {
        hotspot_padding = 1,
    },
})
