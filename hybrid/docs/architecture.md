# Architecture

Decision record for Aether. Written 2026-09-02 from a source audit of all three
upstreams at the commits recorded in `AGENTS.md`.

---

## 1. What this project is

One Quickshell desktop shell that combines the features of **MiDnight Shell** and **OP-Caelestia**
on top of upstream **Caelestia**, presented to the user as a single shell with a settings UI — not
as a launcher that picks between three shells.

From a user's perspective there is one thing to install and one thing to update. Upstream changes
are integrated by maintainers, not by users.

---

## 2. The finding that shaped the design

The original plan was a runtime *implementation registry*: every major component would exist twice
(OP and MiDnight), with a Nexus selector choosing which one instantiates, backed by shared services
and per-fork compatibility adapters.

The audit showed the forks do not overlap enough for that to pay off.

```
Files touched by OP:        133
Files touched by MiDnight:  456
Files touched by BOTH:       48
```

Component by component:

| Component | OP | MiDnight | Two implementations? |
|---|---|---|---|
| Dock | `modules/dock/`, 3 files, own Wrapper/window | `modules/bar/components/Dock.qml`, a bar component | No — different things entirely |
| Bar | 2 files, +16 lines | 19 modified, 10 new | No — only MiDnight |
| Overview | 12 files | — | No — only OP |
| Wallpaper | 1 line in `Wallpapers.qml` | 125 → 486 lines | No — only MiDnight |
| Clipboard, emoji picker, window switcher, shimeji | — | yes | No — only MiDnight |
| Hotspot, BtAgent, GPU detection, theme manager | yes | — | No — only OP |
| Lock centre | `PatternGrid`, `PowerConfirm`, `LockActions` | `Center`/`Content` redesign | **Yes** |
| Audio popout | +399/-6 | +104/-66 | **Yes** |
| Background / desktop clock | +30/-90 | +170/-5 | **Yes** |
| Colours | +52/-2 | +44/-9 | **Yes** |

**Four** genuine dual-implementation sites, not twelve. So there is no `2^12` combinatorial space —
there is a ~90% disjoint feature set plus four contested components.

That inverts the primitive: **a feature flag, not an implementation selector.**

Building a registry, host/Loader indirection, compat adapters and per-component contracts for four
sites would be infrastructure for a problem the codebase does not have.

---

## 3. The other finding: upstream is moving fast underneath both forks

In the 13 days after the fork points, upstream shipped 197 files, +6416/-5048, including:

- `refactor(config): rewrite config module (#1861)`
- `refactor: rearrange plugin layout (#1896)`
- A new `plugin/src/Aether/Settings/` C++ module — `schema`, `node`, `rootnode`, `objectnode`,
  `listnode`, `settingsfile`, `codecs`, `changebatcher`, `quarantine`, and **`layerregistry.hpp`**
- `feat(services): migrate NetworkUsage from QML to C++ (#1860)` — which both forks wrote in QML
- A mass style sweep (scoped enums, `u""_s`, include ordering, clang-tidy)

Both forks still carry the **old** plugin layout (`Internal/`, `appdb`, `imageanalyser`).

Two consequences:

1. `LayerRegistry` is a config layering system with fallback chains
   (`ConfigRoot(path, fallback, parent)`, `forScreen(name)`). It obsoletes MiDnight's own
   per-monitor config work, and it is the mechanism the feature defaults build on.
2. Deferring the upstream catch-up makes it strictly worse. It is Phase 2 for that reason.

---

## 4. Decisions

### D1 — Baseline is MiDnight

Porting OP into MiDnight moves ~8.9k lines that are unusually well-isolated: `modules/dock/` (3
files), `modules/overview/` (12), `services/{Hotspot,BtAgent,Nmcli}.qml`,
`plugin/src/Aether/Services/gpu.{cpp,hpp}`, the theme manager, ~10 Nexus pages, and theme assets.
Estimate: 2-3 weeks.

Porting MiDnight into OP moves 33.5k lines across 456 files including 54 C++ files. Months.

The original reason to prefer OP — "it already has Nexus" — does not hold: `modules/nexus/` is
upstream (66 files upstream, 77 OP, 96 MiDnight). MiDnight extended it further than OP did.

**Cost accepted:** MiDnight's maintenance debt — disabled CI (T9), unlinted code, and per-monitor
config that upstream has superseded (T7). Phase 0 exists to pay this down immediately.

**Alternative considered and rejected:** baseline on upstream `main` and re-land both forks cleanly.
Architecturally purest, but 33.5k lines of re-landing, and MiDnight's author already merges upstream
periodically — we would be permanently duplicating their work.

### D3 — Feature flags, with a capped variant list

```jsonc
{
  "hybrid": {
    "features": {
      "overview": true, "videoWallpaper": true,
      "badApple": false, "hotspot": true, "btAgent": true
    },
    "variants": {
      "audioPopout": "op",
      "overview": "midnight",
      "dock": "midnight"
    }
  }
}
```

`features` carries only the imported features that cost something when they are on: an extra
window, a video decoder, a poll loop. A launcher mode or a settings page costs nothing unused, so
it is simply always available and has no flag (the Hybrid page and its toggles are gone as a
result). `variants` covers only overlaps that have two implementations to choose between, and is capped at ~6 entries (D4). Growth past that means the design is drifting back
toward the rejected registry.

Implement `variants` with Loader hosts **only** where the component is weakly referenced —
`audioPopout` is a leaf and qualifies (the lock centre would too, once its OP side is importable). Anything inside the Panels/Interactions graph
(T1, T2) gets merged into one implementation with config properties instead.

### D5 — Services merge, never dual-implement

The forks extended a shared service set rather than forking it. Only `Audio.qml`, `Colours.qml` and
`Wallpapers.qml` are touched by both, and the Audio conflict resolves by keeping both sides (T8).
Every other service addition is disjoint.

The feared outcome — two PipeWire services, two Hyprland services — cannot happen here, and T5
explains why shadowing a singleton would not achieve it anyway.

### D6 — One CLI

`dim-ghub/midnight-cli` and `dim-ghub/caelestia-cli` are the same repository at the same commit: a
fork of `caelestia-dots/cli`, 18 files, +849/-88. It installs its binary as **`caelestia`**, and every
QML call site in all three shells is `["caelestia", ...]`.

You therefore cannot install both. Fork `caelestia-dots/cli`, apply MiDnight's delta (video wallpaper
and `--extract-thumbs`, extended `screenshot`, `record --fps`, `search`, astra scheme), ship as
`caelestia-hybrid-cli` providing `/usr/bin/caelestia`. Upstream the genuinely general parts.

### D8 — Superseded: there are no presets

Presets were planned as config layers beneath the user's layer, with the preset *name* stored so
"Recommended Hybrid" could improve later. That is gone. Once the always-on features lost their flags
and the rest moved to the page that uses them, a preset was only a bulk shortcut over five switches
and a handful of variants — and an invisible one, since the selector had no home that made sense.

Every setting now has a static default in the compiled schema and exactly one switch on its Nexus
page. `hybrid/presets/*.json` remain as smoke-matrix inputs, not as a settings feature. The variant
defaults preserve what the old recommended preset chose (`audioPopout` is OP, the rest MiDnight).

### D9 — Merge upstream, cherry-pick OP

- Upstream is a true ancestor: `git merge caelestia/main`. Never rebase.
- OP shares ancestor `ad8dca0a` with our line, so `git cherry-pick -x` works directly on its 49
  commits. No patch files, no subtree, no submodules.
- `git rerere` is enabled by `bootstrap.sh` — the same conflicts recur across repeated merges, and
  this is the single highest-value setting for the project.
- One sync branch per upstream (`sync/op/YYYY-MM-DD`), never a combined sync.

**Rejected: subtree** (imports upstream's whole tree, including files we deleted) and **submodules**
(cannot express "our file is upstream's file plus edits").

**Rejected: `upstreams.lock.json`.** Merge commits and `cherry-pick -x` already record integration
points; a hand-maintained ledger drifts. `hybrid/tools/upstream-status.sh` derives the same report
from git on demand.

For monitoring: a scheduled workflow comparing pinned vs. upstream HEAD that opens an **issue** —
never a PR, never an automatic merge into `main`.

### D11 — Hyprland settings persist through hypr-vars.lua

The shell writes exactly one Hyprland file: `~/.config/caelestia/hypr-vars.lua`, the override table
that the dotfiles' `hyprland.lua` merges into `variables`. Every compositor setting the shell owns
is written there as an override; clearing the key restores the user's `variables.lua` value. The
live `hyprctl eval` pushes stay, but only as an immediate preview — persistence is the config, not
the running session.

The editor for `hypr-user.lua` (Hyprland → User configuration) points lua-language-server at
Hyprland's own generated stub in `/usr/share/hypr/stubs` (via `hl.meta.lua`), so `hl.` completes,
dispatcher arguments are checked, and `hl` is not an undefined global even though the compositor's
API only exists at runtime. `assets/lua/hyprland-api.lua` is a smaller fallback for installs that
lack the generated stub; the language server sees exactly one of the two.

The editor owns its own interaction layer. The TextEdit lives inside a Flickable, so an overlay
`MouseArea` supplies the I-beam over the text (and an arrow over the line-number gutter), closes
the completion popup on press rather than release, and opens a right-click menu (undo/redo,
cut/copy/paste, select all). Tab/Shift+Tab indent or dedent the selected lines, Ctrl+Z,
Ctrl+Shift+Z / Ctrl+Y undo and redo, Ctrl+Backspace/Delete remove a word, and the footer shows the
caret line and column. Shift+wheel scrolls horizontally, plain wheel scrolls vertically even when
the pointer is over the gutter.

A few options need variables upstream's dotfiles do not define: overview blur, solid-text windows,
and the animation speed / match-shell pair. `hybrid/hypr/` holds the complete config side — the
entry that merges `hypr-vars`, `variables.lua`, every module that consumes a Nexus-written key
(`general`, `decoration`, `input`, `gestures`, `group`, `rules`, `animations`, `keybinds`, `env`,
`execs`), their `utils/` dependencies and `scheme/default.lua` — as full copies rather than
fragments, so setting a machine up is copying the tree; `hybrid/hypr/README.md` maps every Nexus
setting to the key it writes.

Rejected: keeping these choices only in `~/.local/state` (they vanish with a compositor restart and
need the shell to push them again) and writing the user's dotfiles directly (that is a separate
checkout upstream updates; an editor conflict would silently drop the settings).

### D12 — Aether ships its own Qt platform theme

Qt applications do not read any of this shell's state, so every one of them renders in whatever
palette the Qt platform theme happens to supply — on this class of machine, usually KDE's, from a
`kde` package the desktop does not otherwise use. `plugin/src/Aether/QtTheme/` closes that gap
with a `QPlatformTheme` that reads the scheme the shell is already showing.

The alternative was depending on the AUR `qtengine` package, which the caelestia CLI already writes
a config for. It was rejected on ownership grounds, not on quality: qtengine is a good shape to
copy, but it is a second package that must be rebuilt after every Qt upgrade, and its config
(`~/.config/qtengine/config.json`) would then be the thing that decides the colours. Building it
in-tree means the theme rebuilds exactly when the shell does, from the same Qt.

What it does: `palette()`, `themeHint()` for the icon theme and the widget style, and a file
watcher that re-applies them when `scheme.json`, `shell.json`, `kdeglobals` or the CLI's Qt config
is rewritten.

Where each of those comes from matters, and the rule is the same one the rest of the shell
follows — the session's own setting first, the CLI's generated template last:

| property | source, in order |
|---|---|
| palette | `scheme.json` |
| widget style | `appearance.qtStyle` in `shell.json`, then Kvantum if a theme is configured, then the CLI's style, then Fusion |
| icon theme | `[Icons] Theme` in `kdeglobals`, then the CLI's `iconTheme`, then `Papirus-<mode>` |
| font | **none** — `font()` returns nullptr, so Qt takes it from fontconfig, which is where the shell's "App fonts" page writes |
| KDE applications | `qApp->setProperty("KDE_COLOR_SCHEME_PATH", …)` pointing at `~/.local/state/caelestia/aether.colors`, generated from the same `scheme.json` |

That last row is not a detail. KDE applications do not paint from `QPalette` — Dolphin's places
panel asks `KColorScheme`, which prefers the `KDE_COLOR_SCHEME_PATH` application property and
otherwise falls back to a scheme of its own. With the property unset, that fallback gave dark text
on a dark background while every probe of `QApplication::palette()` reported the correct colours,
which is why the first three attempts at this looked like a Kvantum problem. Measured on the
sidebar: `#606069` before, `#AFB4BD` after, `#B5BAC3` under KDE.

The file it points at is Aether's own: `~/.local/state/caelestia/aether.colors`, written from
`scheme.json` on every reload — atomically, and only when the bytes changed, since every Qt
application runs this at startup and a needless rewrite would wake every KColorScheme watcher on
the desktop. The CLI's `qtengine/caelestia.colors` is the fallback for a machine that has no
`scheme.json` yet.

The icon theme and the font were both wrong at first: they were read from the CLI's
`qtengine/config.json`, which is generated from a template (`Papirus-Dark`, `Sans Serif 12`) on
every scheme change. That silently replaced a session's `kora` icons and its fontconfig font, and
looked like "the theme is wrong" while the palette was in fact identical to KDE's.

What it deliberately does not do:

- **No Qt5 leg.** Nothing here is Qt5, and qtengine's Qt5 tree is half its code and needs an
  explicit `QT5_PLUGINDIR`.
- **No style plugin.** Qt's own Fusion style already respects the palette; a proxy style would add
  a second library and a `QStyleFactory` key for no visible gain. The configured style name is
  still honoured when the factory can create it.
- **No KDE `.colors` parser.** `scheme.json` already holds the M3 tokens, in the file the shell
  reads; parsing the KDE format would be a second copy of the same colours.

#### Kvantum is a style, not a palette source

Kvantum is the one widget style that ships a palette of its own: it paints from its theme SVG and
replaces the application palette in `polish()`. Measured: `QT_QPA_PLATFORMTHEME=aether` with
`QT_STYLE_OVERRIDE=kvantum` reported the Kvantum theme's `#1c202f`/`#008080`, not the scheme's
`#130d09`/`#f2bc90`. Two ways out were considered and rejected:

- **Recolouring the theme.** Rewriting `[GeneralColors]` and every matching literal in the SVG does
  produce the right palette (verified against a copy of the active theme), but it writes a
  generated theme into `~/.config/Kvantum`, goes stale whenever the user picks a different Kvantum
  theme, and inherits gradients designed around the original colours.
- **Wrapping it in a `QProxyStyle`.** Restoring our palette after Kvantum's `polish()` only moves
  the mismatch: backgrounds still come from the theme SVG, so text and surfaces disagree.

So the engine selects Kvantum when the user has configured one — `kvantummanager` writing
`~/.config/Kvantum/kvantum.kvconfig` is the only signal in the tree that a person chose a style by
hand, while the style named in the CLI's config is regenerated from a template on every scheme
change — and then stops pushing the palette, because the palette is Kvantum's. That is the whole
feature: widgets keep the shape the user picked, and the engine does not fight it. Qt Quick
applications create no `QStyle`, so the shell and its surfaces stay on the scheme either way.

The choice itself is a setting, not an environment variable: `appearance.qtStyle` in
`~/.config/caelestia/shell.json`, exposed as **Look & feel → Qt applications → Widget style**, with
`Automatic` as the first entry and every style Qt can create after it. It cannot live where qt6ct
and qtengine keep theirs — the caelestia CLI regenerates `~/.config/qtengine/config.json` from a
template on every scheme change (`utils/theme.py: apply_qt`), so a value written there survives only
until the next colour switch. Aether's own config is the first file in the stack that a person
owns.

The list of styles comes from `CUtils::availableQtStyles()`, which reads the metadata of the style
plugins rather than calling `QStyleFactory`: that class is in QtWidgets, and linking QtWidgets into
the shell to enumerate names would pull the whole widget stack into a QtQuick process.

The hint is only a hint: `QT_STYLE_OVERRIDE` still wins, and when it does, palette ownership follows
the style that actually loaded rather than the name the engine asked for. A configured style that is
not installed keeps its value and falls through to the automatic chain, so uninstalling one does not
silently rewrite the setting.

Installation is two paths because the theme has to be visible to processes the shell never
starts: `make install` puts it in `${prefix}/lib/qt6/plugins/platformthemes`, and
`hybrid/tools/install-qt-theme.sh` copies the build output to `~/.local/lib/qt6/plugins` for a
checkout. `QT_PLUGIN_PATH` and `QT_QPA_PLATFORMTHEME=aether` go in `~/.config/caelestia/hypr-user.lua`,
never in `hybrid/hypr/` — that tree is shared, and an absolute checkout path in it breaks every
other machine (which is why the same rule removed a hardcoded `QML2_IMPORT_PATH`).

---

## 5. Testing

> **Corrected 2026-09-02, on first contact with a real Linux target.** This section previously
> claimed upstream's `lint.yml` already contained a headless smoke test:
> ```bash
> QT_QPA_PLATFORM=offscreen QML2_IMPORT_PATH="…" timeout 2 qs -p .
> ```
> It does not. That line sits under a `# Generate tooling` comment, exists to emit `.qmlls.ini`
> for the linter, and **its exit code is never checked**. Run against this shell it fails
> immediately with `No PanelWindow backend loaded`, because Quickshell's `PanelWindow` is a
> wlr-layer-shell surface and `offscreen` provides no Wayland backend. The failure poisons the
> whole singleton graph (trap T12).

The gate therefore needs a real compositor. `hybrid/tools/smoke-matrix.sh` spawns a **nested
Hyprland** on its own socket, then for each preset boots the shell against it under an isolated
`XDG_CONFIG_HOME` and fails on QML errors. It refuses to run against the live session socket, so
it can never draw over a working desktop, and a cleanup trap tears the compositor down.

Measured cost: ~3s compositor startup, then one window per preset. Three presets at a 12s window
is well under a minute.

**Open item for CI:** a GitHub Actions container has neither a parent Wayland display nor a free
DRM device, so nested Hyprland cannot start there. Either the runner needs a headless
wlroots compositor (`cage`, `sway --headless`) or a virtual DRM device (`vkms`). Resolve this
before wiring `smoke-matrix.sh` into CI; it works locally today.

Because each run costs seconds, arbitrary combinations are affordable — all presets plus a dozen
randomised `features`/`variants` combos per CI run, including deliberately hostile ones (all on, all
off, every variant flipped). That plus `qmllint` covers essentially every failure class a
contract/registry abstraction would have been protecting against.

**Build this before the feature system**, so the feature system lands with coverage. That is Phase 1.

Inherit upstream's `lint.yml`, `check-format.yml`, `build.yml` and `check-pr-title.yml` unchanged
except the container image.

---

## 6. Roadmap

```
Phase 0   Fork MiDnight. Re-enable check-format + lint CI. Fix the backlog.        ~1 wk
Phase 1   Offscreen smoke-test harness + preset matrix runner in CI.               ~1 wk
Phase 2   Merge upstream/main: config rewrite, plugin rearrange, style sweep.     2-4 wks
          Drop MiDnight per-monitor config in favour of LayerRegistry.
Phase 3   hybrid.features flag system + Nexus feature pages.                       ~1 wk
Phase 4   Import OP's dock behind its own flag.            <- PROOF OF CONCEPT
Phase 5   Import OP overview, hotspot/BtAgent/Nmcli, GPU detection, themes.       3-4 wks
Phase 6   Single merged CLI.                                                       ~1 wk
Phase 7   The three importable variants. Merge where possible; Loader-host the
          audio popout. The lock centre waits on Phase 8.
Phase 8   Security: rework or drop OP's pattern lock. Blocks any release
          shipping pattern auth.
```

Phase 2 precedes Phase 3 deliberately: the feature defaults build on the config system we keep, not the one
upstream just deleted.

### Why the dock is the proof-of-concept

Not because it proves dual-implementation — it cannot, since MiDnight has no dock module. It is the
right first slice because it proves the things that actually carry risk:

- cross-fork import works end to end, with provenance
- the feature-flag system gates a real module
- the Panels / Interactions / Regions coupling (T1, T2) is survivable
- the smoke harness catches breakage
- it is visually obvious when it works, and it is not authentication

If this slice takes more than ~3 weeks, that is the signal to reconsider scope before committing
further.

---

## 7. Explicitly not doing

- A runtime implementation registry with per-component selectors (§2).
- A `variants/midnight/` parallel source tree — T5 shows singleton shadowing does not work, and D5
  removes the need.
- Per-fork compatibility adapters over shared services — the services are already shared.
- Sub-component mixing inside wallpaper (T6) or lockscreen auth (T3).
- Swapping the bar (T2).
- Two CLIs, or an adapter layer over two CLIs (D6).
- Automatic merges of upstream into `main`.
- Shipping OP's pattern lock unmodified (T3).
