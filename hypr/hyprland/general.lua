local vars = require("variables")

hl.config({
    general = {
        layout          = vars.layout,

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
        fullscreen_on_one_column = vars.scrollingFullscreenOnOneColumn,
        focus_fit_method         = vars.scrollingFocusFitMethod,
        column_width             = vars.scrollingColumnWidth,
        follow_focus             = vars.scrollingFollowFocus,
        follow_min_visible       = vars.scrollingFollowMinVisible,
        explicit_column_widths   = vars.scrollingExplicitColumnWidths,
    },
})
