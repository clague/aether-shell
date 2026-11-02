-- Rules the shell relies on. Two separate insertions, marked below.

-- 1. In ~/.config/hypr/hyprland/rules.lua, directly AFTER the general opacity rule:
--
--     hl.window_rule({ match = { fullscreen = false }, opacity = vars.windowOpacity .. " override" })
--
-- Later rules win, so the solid-text rule has to come after it.
if vars.solidTextWindows then
    hl.window_rule({ match = { class = vars.solidTextClasses }, opacity = "1.00 override" })
end

-- 2. In the "Layer rules" section of the same file, next to the other caelestia-* rules:
hl.layer_rule({ match = { namespace = "caelestia-overview" }, blur = vars.overviewBlur, ignore_alpha = 0.2 })
