local vars = require("variables")

hl.config({
    animations = {
        enabled = true,
    },
})

-- Animation curves
hl.curve("specialWorkSwitch", { type = "bezier", points = { { 0.05, 0.7 }, { 0.1, 1 } } })
hl.curve("emphasizedAccel", { type = "bezier", points = { { 0.3, 0 }, { 0.8, 0.15 } } })
hl.curve("emphasizedDecel", { type = "bezier", points = { { 0.05, 0.7 }, { 0.1, 1 } } })
hl.curve("standard", { type = "bezier", points = { { 0.2, 0 }, { 0, 1 } } })

-- Motion written by the shell (Settings > Hyprland > Spacing & animations). "animSpeed" scales
-- every leaf; "animMatchShell" instead hands the moving/fading leaves the shell's own curves and
-- speeds, so windows move like the shell does.
local function shellCurve(value, fallback)
    local a, b, c, d = tostring(value or ""):match(
        "^%s*([%d%.%-]+)%s*,%s*([%d%.%-]+)%s*,%s*([%d%.%-]+)%s*,%s*([%d%.%-]+)%s*$")
    if not a then return fallback end
    return { { tonumber(a), tonumber(b) }, { tonumber(c), tonumber(d) } }
end

local matchShell = vars.animMatchShell == true

if matchShell then
    hl.curve("shellSpatial", { type = "bezier", points = shellCurve(vars.animSpatialCurve, { { 0.38, 1.21 }, { 0.22, 1 } }) })
    hl.curve("shellEffects", { type = "bezier", points = shellCurve(vars.animEffectsCurve, { { 0.34, 0.88 }, { 0.34, 1 } }) })
end

local spatialLeaves = { windowsIn = true, windowsMove = true, workspaces = true, specialWorkspace = true }
local effectLeaves = { windowsOut = true, fade = true, layers = true }

local function animation(leaf, enabled, speed, bezier, style)
    local spatial = spatialLeaves[leaf] == true
    local effect = effectLeaves[leaf] == true

    if matchShell and spatial then
        speed, bezier = vars.animSpatialSpeed, "shellSpatial"
    elseif matchShell and effect then
        speed, bezier = vars.animEffectsSpeed, "shellEffects"
    else
        speed = (speed or 1) * (vars.animSpeed or 1)
    end

    speed = math.max(0.5, math.floor((speed or 1) * 10 + 0.5) / 10)

    local config = { leaf = leaf, enabled = enabled, speed = speed, bezier = bezier }
    if style then config.style = style end
    hl.animation(config)
end

-- Animation configs
animation("layersIn", true, 5, "emphasizedDecel", "slide")
animation("layersOut", true, 4, "emphasizedAccel", "slide")
animation("fadeLayers", true, 5, "standard")

animation("windowsIn", true, 5, "emphasizedDecel")
animation("windowsOut", true, 3, "emphasizedAccel")
animation("windowsMove", true, 6, "standard")
animation("workspaces", true, 5, "standard")

animation("specialWorkspace", true, 4, "specialWorkSwitch", "slidefadevert 15%")
animation("fade", true, 6, "standard")
animation("fadeDim", true, 6, "standard")
animation("border", true, 6, "standard")
