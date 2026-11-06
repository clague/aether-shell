local scheme = require("scheme.current")
local vars   = require("variables")

hl.config({
    group = {
        col = {
            border_active          = vars.activeWindowBorderColour,
            border_inactive        = vars.inactiveWindowBorderColour,
            border_locked_active   = vars.activeWindowBorderColour,
            border_locked_inactive = vars.inactiveWindowBorderColour,
        },
        groupbar = {
            font_family               = vars.groupbarFontFamily,
            font_size                 = vars.groupbarFontSize,
            gradients                 = vars.groupbarGradients,
            gradient_round_only_edges = vars.groupbarGradientRoundOnlyEdges,
            gradient_rounding         = vars.groupbarGradientRounding,
            height                    = vars.groupbarHeight,
            indicator_height          = vars.groupbarIndicatorHeight,
            gaps_in                   = vars.groupbarGapsIn,
            gaps_out                  = vars.groupbarGapsOut,
            text_color                = vars.groupbarTextColour,
            col                       = {
                active          = vars.groupbarActiveColour,
                inactive        = vars.groupbarInactiveColour,
                locked_active   = vars.groupbarLockedActiveColour,
                locked_inactive = vars.groupbarLockedInactiveColour,
            },
        },
    },
})
