local vars = require("variables")
local fn   = require("utils.functions")

hl.config({
    gestures = {
        workspace_swipe_distance                 = vars.workspaceSwipeDistance,
        workspace_swipe_cancel_ratio             = vars.workspaceSwipeCancelRatio,
        workspace_swipe_min_speed_to_force       = vars.workspaceSwipeMinSpeed,
        workspace_swipe_direction_lock           = vars.workspaceSwipeDirLock,
        workspace_swipe_direction_lock_threshold = 10,
        workspace_swipe_create_new               = vars.workspaceSwipeCreateNew,
    },
})

hl.gesture({ fingers = vars.workspaceSwipeFingers, direction = "horizontal", action = "workspace" })
hl.gesture({ fingers = vars.gestureFingers, direction = "up", action = "special", workspace_name = "special" })
hl.gesture({
    fingers   = vars.gestureFingers,
    direction = "down",
    action    = fn.toggle("specialws"),
})
hl.gesture({
    fingers   = vars.gestureFingersMore,
    direction = "down",
    action    = function()
        hl.exec_cmd(vars.sleepGestureCmd)
    end,
})
