# Hyprland config the shell expects

The shell never edits `~/.config/hypr` itself. The one file it writes is
`~/.config/caelestia/hypr-vars.lua`, the override table that the dotfiles' `hyprland.lua` merges
into `variables`:

```lua
local overrides = require("hypr-vars")
for k, v in pairs(overrides) do vars[k] = v end
```

That makes every key in the table an override of the matching `variables.lua` default, which is
why clearing a key is the way to reset: delete it and the user's own value applies again.

The directory you are reading is the **reference copy of the config side** of that contract. It is
not installed by the build and not read at runtime — the shell only knows the key names. Keep it in
sync with the dotfiles checkout (`~/.config/hypr`), and copy from here when you set the dotfiles
up on a new machine.

## Files

| file here | goes into | notes |
|---|---|---|
| `variables.shell.lua` | appended to `~/.config/hypr/variables.lua` | keys the shell writes that upstream `variables.lua` does not define |
| `rules.shell.lua` | `~/.config/hypr/hyprland/rules.lua` | two insertions, with the exact spot described in the file |
| `animations.lua` | replaces `~/.config/hypr/hyprland/animations.lua` | applies `animSpeed` and `animMatchShell` to every leaf |

## What writes what

| Nexus page | setting | keys in `hypr-vars.lua` | writer |
|---|---|---|---|
| Hyprland → Window effects | blur, shadow, rounding, border colours | `blurEnabled`, `blurSpecialWs`, `blurPopups`, `blurInputMethods`, `blurSize`, `blurPasses`, `blurXray`, `shadow*`, `windowRounding`, `activeWindowBorderColour`, `inactiveWindowBorderColour` | `Hypr*Row` via `services/HyprVars.qml` |
| Hyprland → Window effects | window opacity | `windowOpacity` | `services/Glass.qml` |
| Hyprland → Window effects | solid text windows | `solidTextWindows`, `solidTextClasses` | `services/Glass.qml` |
| Hyprland → Window effects | blur behind the overview | `overviewBlur` | `services/Glass.qml` |
| Hyprland → Spacing & animations | gaps preset / sliders | `windowGapsIn`, `windowGapsOut`, `windowBorderSize` | `services/Density.qml` |
| Hyprland → Spacing & animations | animation speed / match shell | `animSpeed`, `animMatchShell`, `animSpatialCurve`, `animEffectsCurve`, `animSpatialSpeed`, `animEffectsSpeed` | `services/Motion.qml` |
| Hyprland → Variables | apps, touchpad, misc | the same names as `variables.lua` | `Hypr*Row` via `services/HyprVars.qml` |
| Hyprland → Keybinds | every bind | `kb*` | `pages/hyprland/HyprKeybindsPage.qml` |

`services/Glass.qml`, `services/Motion.qml` and `services/Density.qml` also push their values to
the running compositor (`hyprctl eval` / live options), so a slider has an immediate effect even
before a reload. Persistence is the config side above; the live push is only the preview.

`solidTextClasses` is a regex maintained by `Glass.solidClasses`. The shell writes it whenever the
toggle changes, so the value in `variables.shell.lua` (and in `variables.lua`) is just the default
for a machine where the shell has not written that key yet.

## If a key or file is missing

Nothing breaks, but nothing persists either. The shell still applies the change live for the
current session, then writes a `hypr-vars.lua` key that no one reads and the value is back to the
`variables.lua` default after the next Hyprland start. `hyprctl configerrors` stays empty.

This is also what happens after a dotfiles update that replaces `variables.lua`, `rules.lua` or
`animations.lua`: re-apply the three files from this directory. `hybrid/docs/provenance.md`
records that the shell side owns this contract, not the dotfiles.
