local vars = require("variables")

hl.config({
    general = {
        layout          = "dwindle",

        allow_tearing   = vars.allowTearing, -- Allows `immediate` window rule to work
        resize_on_border = vars.resizeOnBorder,

        gaps_workspaces = vars.workspaceGaps,
        gaps_in         = vars.windowGapsIn,
        gaps_out        = vars.windowGapsOut,
        border_size     = vars.windowBorderSize,

        col             = {
            active_border   = vars.activeWindowBorderColour,
            inactive_border = vars.inactiveWindowBorderColour,
        },
    },

    dwindle = {
        preserve_split = vars.preserveSplit,
        smart_split    = vars.smartSplit,
        smart_resizing = vars.smartResizing,
    },

    scrolling = {
        fullscreen_on_one_column = true,
        focus_fit_method         = 1,
        column_width             = 0.5,
        follow_focus             = true,
        follow_min_visible       = 0.0,
        explicit_column_widths   = "0.35, 0.5, 0.65, 1.0",
    },
})
