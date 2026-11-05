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

This directory is the **complete config side** of that contract: full files, not fragments, and
every module that consumes a variable Nexus writes. It is the dotfiles' tree with the shell
additions already merged, so setting a machine up is copying it, not patching snippets into an
existing checkout.

Based on `caelestia-dots/caelestia` `f9c50b5`. The merge keeps the local `hyprmoncfg` loader at the
end of `hyprland.lua`; everything else is upstream plus the shell contract.

Nothing here is installed by the build or read at runtime; the shell only knows the key names.
Keep it in sync with the dotfiles checkout (`~/.config/hypr`) when either side changes.

## Files

| path here | goes into |
|---|---|
| `hyprland.lua` | `~/.config/hypr/hyprland.lua` |
| `variables.lua` | `~/.config/hypr/variables.lua` |
| `hyprland/` | `~/.config/hypr/hyprland/` |
| `utils/` | `~/.config/hypr/utils/` |
| `scheme/default.lua` | `~/.config/hypr/scheme/default.lua` |

Copy the tree over the dotfiles checkout. `scheme/current.lua` is not stored: `hyprland.lua`
creates it from `scheme/default.lua` on first start, and the scheme commands rewrite it.

Every module that consumes a variable Nexus writes is here, not just the ones that needed a
shell addition:

| variable group | consumer |
|---|---|
| gaps, border size, `activeWindowBorderColour` | `hyprland/general.lua`, `hyprland/group.lua` |
| tearing, border resizing, dwindle behaviour | `hyprland/general.lua` |
| blur, shadow, rounding, rounding power, dim, opacity | `hyprland/decoration.lua`, `hyprland/rules.lua` |
| solid-text windows, overview blur, single-window gaps | `hyprland/rules.lua` |
| keyboard layout/rate, mouse, touchpad | `hyprland/input.lua` |
| gesture fingers, workspace swipe | `hyprland/gestures.lua` |
| vrr, dpms, session lock, Hyprland logo, misc toggles | `hyprland/misc.lua` |
| cursor theme/size, volume step, sleep gesture | `hyprland/env.lua`, `hyprland/execs.lua`, `hyprland/keybinds.lua` |
| animation speed / match shell | `hyprland/animations.lua` |
| every `kb*` bind | `hyprland/keybinds.lua` |

`hyprland/keybinds.lua` and `hyprland/execs.lua` require `utils/functions.lua`, which requires
`utils/json.lua`; `variables.lua` requires `scheme.current`. That is the whole dependency set.

Leave the user-owned files alone: `~/.config/caelestia/hypr-user.lua` (loaded by `hyprland.lua`
after the modules) and `~/.config/hypr/hyprmoncfg-monitors.lua` (generated per machine, also
loaded by the entry). `hyprland/env.lua` keeps this machine's `QML2_IMPORT_PATH` line for the
development checkout; drop it when installing a packaged shell.

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
| Hyprland → Window effects | window groups | `groupbar*` | `Hypr*Row` via `services/HyprVars.qml` |
| Hyprland → Spacing & animations | layout and scrolling | `layout`, `scrolling*` | `Hypr*Row` via `services/HyprVars.qml` |
| Hyprland → Spacing & animations | window behaviour | `focusOnClose`, `onFocusUnderFullscreen`, `allowSessionLockRestore` | `Hypr*Row` via `services/HyprVars.qml` |
| Hyprland → Input | swipe direction threshold | `workspaceSwipeDirLockThreshold` | `Hypr*Row` via `services/HyprVars.qml` |
| Hyprland → Keybinds | every bind | `kb*` | `pages/hyprland/HyprKeybindsPage.qml` |

`services/Glass.qml`, `services/Motion.qml` and `services/Density.qml` also push their values to
the running compositor (`hyprctl eval` / live options), so a slider has an immediate effect even
before a reload. Persistence is the config side above; the live push is only the preview.

`solidTextClasses` is a regex. It is editable in the Glass section and defaults to
`Glass.solidClasses`; the shell writes the value whenever the toggle changes, so the value in
`variables.lua` is just the default for a machine where the shell has not written that key yet.

## Mouse back/forward in the settings window

Qt only turns `BTN_SIDE`/`BTN_EXTRA` (275/276, what most mice send) into
`Qt.BackButton`/`Qt.ForwardButton`; `BTN_BACK`/`BTN_FORWARD` (278/277) never reach QML. The Nexus window
handles the first pair directly, and the two `mouse:278`/`mouse:277` binds at the end of
`hyprland/keybinds.lua` route the second pair through the shell's global shortcuts
(`caelestia:nexusBack`/`caelestia:nexusForward`, registered in `daemons/Shortcuts.qml`). The binds
are `non_consuming`, so apps that do understand the buttons keep working, and the shell only acts
while a settings window is focused.

A compositor bind on the same button elsewhere in the config would still swallow it, which is the
other way these buttons appear to stop working.

## If a key or file is missing

Nothing breaks, but nothing persists either. The shell still applies the change live for the
current session, then writes a `hypr-vars.lua` key that no one reads and the value is back to the
`variables.lua` default after the next Hyprland start. `hyprctl configerrors` stays empty.

This is also what happens after a dotfiles update replaces one of these five files: copy them in
again from this directory. `hybrid/docs/provenance.md` records that the shell side owns this
contract, not the dotfiles.
