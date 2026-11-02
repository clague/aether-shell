-- Shell-owned keys, appended to ~/.config/hypr/variables.lua.
--
-- They are the defaults for what Nexus and the shell services write into
-- ~/.config/caelestia/hypr-vars.lua; keeping them here means the variable exists (and the
-- override is meaningful) even before the shell writes anything. If a key is missing, the
-- shell still applies the value live, but nothing survives a Hyprland restart.
--
-- The colours/blur/shadow/gap keys the shell also writes already exist upstream
-- (windowGapsIn, windowGapsOut, windowBorderSize, windowOpacity, windowRounding, blur*,
-- shadow*, workspaceGaps, singleWindowGapsOut) and are not repeated here.

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
