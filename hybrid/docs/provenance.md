# Provenance ledger

Every file imported from an upstream gets a row here **in the same commit that imports it**.

All three upstreams are **GPL-3.0**, so the combined work is GPL-3.0 and there is no license
compatibility question. What we still owe: preserved copyright and authorship, preserved license
headers, and history that attributes the imported work. Keeping `git` history and this ledger
satisfies that; squashing an import into an anonymous commit does not.

## Source identifiers

| ID | Repository | Ref audited |
|---|---|---|
| `caelestia` | `caelestia-dots/shell` | `750e67d9` (2026-09-02) |
| `op` | `OVERxPOWERED/op-caelestia-shell` | `621339cf` (2026-08-25) |
| `midnight` | `dim-ghub/midnight-shell` | `bb7b5657` (2026-08-22) |
| `hybrid` | this repository | — |

## Import kinds

| Kind | Meaning |
|---|---|
| `baseline` | Arrived with the MiDnight fork. Not individually listed — the whole tree is `midnight` unless a row says otherwise. |
| `copied` | Imported byte-identical, or with only import-path changes. |
| `adapted` | Imported with real modifications. The row must say what changed and why. |
| `reimplemented` | Written by us based on the upstream behaviour, not its code. |
| `superseded` | Upstream later replaced it. Row records what we dropped (see T7). |

## Rules

1. One row per imported file. Group by feature; keep features in the order they were imported.
2. `adapted` rows need a one-line reason. "Cleanup" is not a reason.
3. When upstream changes a file we `adapted`, the sync branch updates the row's source commit.
4. Prefer `git cherry-pick -x` over copying — it records the source commit automatically and this
   ledger becomes a convenience index rather than the only record.
5. Binary assets (theme GIFs, sounds, shimeji sprites) get rows too. They are the easiest thing to
   lose attribution on and the most likely to carry third-party licensing of their own —
   **check asset provenance separately from code provenance.**

## Ledger

<!-- Add rows below. Keep the newest feature block at the bottom. -->

| Feature | Source | Source commit | Original path | Local path | Kind | Notes |
|---|---|---|---|---|---|---|
| _(baseline)_ | `midnight` | `bb7b5657` | _(whole tree)_ | _(whole tree)_ | `baseline` | Phase 0 fork point |
| video wallpaper | `midnight` | `bb7b5657` | `components/images/CachingVideo.qml` | _(removed)_ | `superseded` | `modules/background/Wallpaper.qml` plus `services/WallpaperPauser.qml` own the playback and pausing now. Dead in MiDnight too. |
| video wallpaper | `midnight` | `bb7b5657` | `services/VideoWallpaperPlayer.qml` | _(removed)_ | `superseded` | Its only user was `CachingVideo.qml`, here and in MiDnight. Orphaned by the row above. |
| bad apple | `midnight` | `bb7b5657` | `modules/background/BadAppleController.qml` | _(removed)_ | `superseded` | `BadApplePlayer` is the singleton the overlay and the toggles actually use. Dead in MiDnight too. |
| _(none)_ | `midnight` | `bb7b5657` | `modules/sidebar/TestComponent.qml` | _(removed)_ | `superseded` | Debug scaffolding: creates a red 100x100 FloatingWindow that logs on click. Never referenced, here or in MiDnight. |
| hotspot | `op` | `621339cf` | `services/Hotspot.qml` | `services/Hotspot.qml` | `adapted` | Four changes. `pollTimer.running` was an unconditional `true`, which runs `nmcli` every 10s forever once the singleton exists, active or not; it is now gated on `GlobalConfig.hybrid.features.hotspot` (adding `import Caelestia.Config`). Three are the credential path (T41): the default password was the published constant `"caelestia1234"`, now empty so nmcli generates a per-install PSK; `startProc`'s stdout was `console.log`ged, and that stdout is where nmcli prints the password, so it is no longer captured; and a successful start now calls `readSavedConfig()` so a generated key reaches the settings field. The rest is mechanical: `qml-section-order.py` moved functions and properties above the child objects, and `qmlformat` rejoined wrapped ternaries. |
| hotspot | `op` | `621339cf` | `modules/nexus/pages/network/HotspotPage.qml` | `modules/nexus/pages/network/HotspotPage.qml` | `adapted` | `modelData` in the connected-clients delegate is qualified through a new `id: clientEntry`, which `qmllint` requires (the tree's own shape, cf. `modules/nexus/common/EthernetSection.qml`). Otherwise formatter-only. Registered as sub-page index 7 of the Network `StackPage`. |
| bt agent | `op` | `621339cf` | `services/BtAgent.qml` | `services/BtAgent.qml` | `adapted` | `Process.running` was an unconditional `true`; now gated on `GlobalConfig.hybrid.features.btAgent` (adding `import Caelestia.Config`). The 3s restart timer re-reads the flag instead of assigning `true` -- that assignment breaks the binding, so it has to carry the gate itself or a crash would resurrect the agent with the feature off. |
| bt agent | `op` | `621339cf` | `scripts/bt-agent.py` | `scripts/bt-agent.py` | `copied` | Verbatim. BlueZ pairing agent over D-Bus, talking to the shell on a `0600` unix socket in `$XDG_RUNTIME_DIR`. Adds runtime deps `python-dbus` and `python-gobject`. |
| bt agent | `op` | `621339cf` | `modules/nexus/pages/bluetooth/BluetoothPairingDialog.qml` | `modules/nexus/pages/bluetooth/BluetoothPairingDialog.qml` | `adapted` | `modelData`/`index` in the passkey-digit delegate qualified through a new `id: digitCell`, which `qmllint` requires. Four `qmllint disable missing-property` on guarded `inputLoader.item` accesses: `Loader.item` is typed `QObject`, so the loaded `FocusScope`'s `inputBuffer` is unknowable there. Mounted in `modules/nexus/Nexus.qml`, not on the pairing page as OP does -- see the note below. |
| theme packs | `op` | `621339cf` | `modules/launcher/services/ThemeManager.qml` | same | `adapted` | Dropped `GlobalConfig.save()`: SettingsFile debounces and persists writes itself since the Phase 2 config rewrite, and ConfigSingleton no longer exposes `save()`. |
| theme packs | `op` | `621339cf` | `modules/launcher/items/ThemeItem.qml` | same | `adapted` | `import qs.modules.launcher.services` carries a `qmllint disable unused-imports`: it is needed for the `ThemeManager.Theme` property type, and qmllint does not count a type used only in a property declaration -- removing it produces three `unresolved-type` warnings instead. |
| theme packs | `op` | `621339cf` | `modules/nexus/pages/wallandstyle/ThemeSelect.qml` | same | `adapted` | Same `save()` removal. Registered as sub-page index 6 of the Wallpaper & style `StackPage`. |
| theme packs | `op` | `621339cf` | `plugin/src/Caelestia/Config/userpaths.hpp` | `userpaths.{hpp,cpp}` | `reimplemented` | OP makes `sessionGif`/`mediaGif`/`lockGif`/`notifBg`/`defaultWall` read-only properties computed from `themeName`, defaulting to `"Shinchan"`. Ours keeps them as ordinary config keys and makes the *theme* supply their default, so a user who has set one specific path keeps it across a theme change -- the same override rule as D8. |
| osd settings | `op` | `621339cf` | `modules/nexus/pages/panels/OsdPanel.qml` | same | `copied` | Settings page for `osd.*`, every key of which our schema already had. Appended to the Panels `StackPage`. |
| power & idle settings | `op` | `621339cf` | `modules/nexus/pages/PowerIdlePage.qml` | same | `adapted` | Three unused imports dropped. A new top-level Nexus page, so `PageRegistry` gains a matching nav entry at the same index -- the two lists are ordinal-coupled (T47). |
| desktop background settings | `op` | `621339cf` | `modules/nexus/pages/wallandstyle/DesktopBackground.qml` | same | `copied` | Settings sub-page for the desktop clock and visualiser. Appended to the Wallpaper & style `StackPage`. |
| lock power confirm | `op` | `621339cf` | `modules/lock/PowerConfirm.qml` | same | `adapted` | Its glass effect used `FastBlur` + `OpacityMask` from `Qt5Compat.GraphicalEffects`, a package this tree depends on nowhere else -- present on the dev machine, absent from the CI container, so every local gate passed while CI failed all seven smoke runs with rc=255 (T52). Rewritten on `MultiEffect`, which does blur and masking in one and is what the rest of the tree uses. OP's `accept()` hardcoded `Config.session.commands.shutdown`, because its lock screen has one dedicated power button. Ours renders `Config.session.buttons`, a list with a command each, so the dialog now takes the command it is confirming and covers all of them. Gated on `hybrid.features.lockPowerConfirm`; without it the lock screen runs session commands immediately, as it did before. |
| theme packs | _(none)_ | — | `assets/themes/{Deadpool,Gojo,Shinchan}/*` (19 files) | _(not imported)_ | `rejected` | Third-party character IP -- Marvel's Deadpool, Gege Akutami's Gojo, Yoshito Usui's Shinchan. The same problem that already removed Pusheen, Bongo Cat and the Chrome dino. `assets/themes/nebula/` is generated instead by `hybrid/tools/mascot/make-theme.py` from this shell's own sparkle. |
| audio popout | `op` | `621339cf` | `modules/bar/popouts/AudioPopout.qml` | `modules/bar/popouts/AudioPopoutOp.qml` | `adapted` | **Renamed, because both forks wrote this file at the same path and upstream owns it.** Ours is upstream's, byte-identical to MiDnight's, so it keeps the canonical name and OP's takes a new one. Dropped an unused `import Quickshell`; one `qmllint disable missing-property` on `chipRepeater.itemAt(i).isSelected`, which qmllint types as `QQuickItem`. The first real `hybrid.variants` site. |
| audio popout | `op` | `621339cf` | `services/Audio.qml` (`getStreamIcon`) | same | `adapted` | OP's popout needs a per-stream icon and our `Audio` had only `getStreamName`. Services merge rather than dual-implement (D5), so the method is ported into our service rather than carried in the popout. |
| audio popout | `op` | `621339cf` | `components/containers/HorizontalFadeFlickable.qml` | same | `copied` | Dependency of OP's popout. Held back from the standalone batch precisely so it would not sit unreferenced. |
| overview | `op` | `621339cf` | `modules/overview/` (11 files) | same | `adapted` | The fifth `hybrid.variants` site. Components imported the parent as `import ".."`, a relative directory import that resolves the files but **not** the generated qmldir's `singleton` line -- so `OverviewState`'s 12 members were all unresolved. Rewritten to `import qs.modules.overview`, which is how the rest of this tree imports, and the two files in the parent directory needed the same self-import. 18 unused imports dropped, two `unresolved-type` disables on `Toplevel.wayland` (existing convention, cf. `modules/BluetoothReconnect.qml`), `modelData` qualified in `WorkspaceCard`. |
| overview | `op` | `621339cf` | `modules/overview/components/GhostWorkspaceCard.qml` | _(not imported)_ | `rejected` | Referenced by nothing, **in OP too** -- dead in the source rather than broken by the import. Same treatment as MiDnight's four dead files rather than an allowlist entry for an orphan. |
| overview | `op` | `621339cf` | `modules/nexus/pages/panels/OverviewPanel.qml` | same | `copied` | Settings page for OP's overview. Appended to the Panels `StackPage`. |
| overview | _(ours)_ | — | `modules/drawers/WorkspaceOverview.qml` | same | `adapted` | MiDnight's side of the variant. Its root must always exist -- `Panels.qml` aliases it, `Regions.qml` reads `offsetScale` for a region and `ContentWindow.qml` feeds a deform matrix from it, so a conditional root would leave three bindings on a null (T1). Its **content** is wrapped in a Loader gated on the variant instead, which is where the cost is: a Repeater tracking every toplevel. Probed both ways -- exactly one implementation's content is built per setting. |
| dock | `op` | `621339cf` | `modules/dock/` (3 files) | same | `adapted` | The sixth `hybrid.variants` entry -- D4's stated cap. `shouldBeActive` gains the variant, which is the whole gate: `offsetScale` follows it, the content Loader keys on it, and the region collapses to the border thickness. `PropertyChanges { target: x; prop: v }` rewritten to the Qt6 `x.prop: v` form; three unused imports dropped. |
| dock | `op` | `621339cf` | `plugin/src/Caelestia/Config/dockconfig.hpp` | same | `reimplemented` | Ported from OP's `ConfigObject` to `settings::ObjectNode` (D7); keys and defaults unchanged. Needed three registrations OP's layout did not: the module source list, `rootnodes.hpp`, and the *attached* `Config.dock` accessor -- the last is why `Config.dock.enabled` resolved as a type but not as a member. |
| dock | `op` | `621339cf` | `modules/nexus/pages/panels/DockPanel.qml` | same | `adapted` | `Icons.getIcon` does not exist here **or in OP** -- replaced with `Quickshell.iconPath`, this tree's idiom. `ScriptModel.values` wants `QList<QJSValue>` and `pinnedApps` is a `QStringList`, so it is spread. |
| dock | _(ours)_ | — | `modules/bar/Bar.qml`, `modules/drawers/Regions.qml`, `components/ScreenState.qml` | same | `adapted` | MiDnight's side is a bar entry, now filtered out unless the variant selects it -- otherwise the machine shows two docks. A region is added for OP's panel, and `ScreenState` gains the `dock` flag its wrapper reads, which also makes `qs ipc call drawers toggle dock` work. |
| hotspot | `op` | `621339cf` | _(not imported)_ | _(deferred)_ | `deferred` | `services/BtAgent.qml` and `scripts/bt-agent.py` travel with Hotspot in the skill's import table but are an unrelated feature -- a Bluetooth pairing agent. Held for their own branch and flag rather than smuggled in behind `hybrid.features.hotspot`. |
| dock magnification | `op` | `fa5296e8` | `modules/dock/Content.qml` | same | `adapted` | Hover-magnification curve (`getMagnificationScale`), per-delegate `scale`/`y`/`z` bindings and the `dock.scrollToLauncher` key. Ported onto our adapted dock, which had drifted ~424 lines from OP; the new key is a `CONFIG_PROPERTY` in our `settings::ObjectNode` DockPanel form, with a Nexus toggle. Rides the existing `hybrid.features.dock`/`hybrid.variants.dock` gates. |
| transparency action | `op` | `4ff13cb5` | `modules/launcher/services/Actions.qml`, `services/Colours.qml` | same | `adapted` | `Colours.toggleTransparency` (notify-send toast) plus a default launcher action. Ours presents actions through the typed `launcher.actions` schema, so the entry lives in `launcherconfig.hpp`'s default list instead of OP's static one. Reuses `appearance.transparency.enabled`; no new key. |
| user themes dir | `op` | `5473a111` | `modules/launcher/services/ThemeManager.qml`, `plugin/src/Caelestia/Config/userpaths.{hpp,cpp}`, `utils/Paths.qml` | same | `adapted` | Only the user-theme-directory delta: a second `FileSystemModel`/`Variants` pair in ThemeManager and a user-dir lookup ahead of the bundled path in `themeAsset`. Assets are **not** imported -- our own generated theme already ships (see the asset watchlist), and OP's are the rejected character set. Path uses our prefix (`~/.local/share/caelestia/themes`), not OP's `op-caelestia`; the theme-name default stays empty, not Nebula. |
| pomodoro timer | `op` | `11b366f7`, `15bb3aca`, `9af47937` | `services/Pomodoro.qml`, `modules/dashboard/dash/{DateTime,PomodoroShapes}.qml` | same | `adapted` | Clock/timer switcher in `DateTime` plus the M3 shape-heap vessel. New `dashboard.pomodoro.*` subobject (focus/short/long durations, sessions before long break, default-to-timer) and a `hybrid.features.pomodoro` flag gating the service in ServiceLoader and hiding the switcher/forcing the clock view when off. Nexus gets a Pomodoro section; presets and feature count updated to 15. OP's COMPLETION/UPDATE_ROADMAP edits dropped. |
| scratchpad | `op` | `0ddbb609` | `modules/quicknote/` (2 files), `services/QuickNoteState.qml` | same | `adapted` | A keyboard-driven note overlay with tags, auto-save and a per-screen LazyLoader. New `hybrid.features.quicknote` flag gates the scope in shell.qml and gets a Nexus toggle; the settings page is registered as the last Panels sub-page (index 18 here, not OP\'s 14). Adapted: the notes directory defaults to `~/Notes` instead of OP\'s personal path; the listing and editor launch are argv-style (`mkdir` + `find`, and the configured terminal) instead of an interpolated `sh -c`, which the shell-safety gate rejects; the drawer mutual-exclusion graph is re-threaded onto ours\' `ScreenState` (which also carries `workspaceDrawer` and `dock`). |
| Google Calendar sync | `op` | `4b2150c6` | _(not imported)_ | _(deferred)_ | `deferred` | The service, its stdlib-only python helper and the Nexus page are self-contained, but the dashboard half rewrites `modules/dashboard/dash/Calendar.qml` around an event-tooltip structure and our copy carries a 269-line Pastafarian holiday layer (indicators, hover tooltip, `Tr.locale`, renderType, month-wheel navigation). Merging the two is a rewrite of the file, and the feature needs user OAuth credentials to be exercised at all, so it is deferred rather than half-merged. The Nexus Services page wiring lands with it. |
| scrollable menus | `op` | `462bd0ea`, `0ff57acc` | `components/controls/Menu.qml` | same | `adapted` | Ours already scrolled with a fixed `maxHeight` cap. Ported the flip-up behaviour, the space measurement and `revealActive()`. The measurement is OP's `0ff57acc` fix -- taken because the original `spaceBelow`/`spaceAbove` bindings loop with the menu's own position -- into a `measure()` called on open and on anchor movement. Also carries 0ff57acc's null guard on `QsWindow.window`. |
| display profiles | `op` | `b903f608`(display half), `cc232706`, `932d3242`, `05069845`, `7811975b`, `89c37a59` | `services/Displays.qml`, `modules/displays/` (3 files), `modules/nexus/{pages/DisplayPage,common/DisplayArrangement,common/InterfaceSizeRow,WindowFactory}.qml`, `scripts/display-draft.py` | same | `adapted` | Live layout control with a 15 s confirm window and revert; saved layouts, mirroring, per-display interface size and delete are applied through the external **hyprmoncfg** binary, declared in the README dependency list as optional (live changes work without it, persistence does not). Nexus gets a top-level Display page at the position our registry already reserved for it; the three confirmation windows are hosted in shell.qml unconditionally like OP does (they are inert without a pending change). The settings-search half of `b903f608` is F1 and is not part of this import. |
| doctor | `op` | `50dc0612`, `185966c6` | `modules/nexus/pages/DoctorPage.qml`, `scripts/doctor.py`, `services/DoctorWatchdog.qml` | same | `adapted` | Health checks (NetworkManager, bluetooth, rfkill, bt-agent, polkit, portals, duplicate wifi profiles) as a Nexus page, plus the background watchdog that re-runs them and persists its interval in state. New `hybrid.features.doctorWatchdog` flag gates the watchdog service and gets a Nexus toggle; the page itself is always available. `SelectRow` gains the `disabled` property the page needs. The search-index regeneration from these commits is F1 and is not imported. |
| look & feel | `op` | `ef8bb3c1`, `9e702c0a`, `988c0bb4`, `5501ef5d`, `89df7ae9` | `modules/nexus/pages/LookAndFeelPage.qml`, `modules/nexus/common/InterfaceSizeRow.qml`, `services/{Density,Glass,Motion,AppFonts}.qml`, `scripts/app-fonts.py` | same | `adapted` | A separate Look & feel page next to Shell Tokens, as decided: Density and Glass push Hyprland gaps/border/blur/opacity live (never editing `variables.lua`), Motion reuses `appearance.anim.durations.scale`, App fonts manages a user fontconfig file plus a text-size adjustment. It sits beside Tokens because Tokens edits the shell\'s own QML tokens while this page edits the compositor and system apps. `InterfaceSizeRow` replaces the display page\'s inline size row and is shared with it. Font family/size in the preview is set through `Qt.font()` because our `StyledText.font` is a font value, not a grouped property scope. |
| settings search | `op` | `b903f608` (search half) | `modules/nexus/{SearchEngine,SearchIndex,SearchResults}.qml`, `scripts/gen-nexus-search-index.py`, `scripts/nexus-search-keywords.json`, `modules/nexus/{NavPane,Nexus,NexusState}.qml`, `modules/nexus/common/PageBase.qml` | same | `adapted` | Full-index search replacing our inherited search-bar filter: ranked token matching, keyboard navigation, and opening a result then scrolling to and flashing the row (`PageBase.highlightRow`). `SearchIndex.qml` is regenerated with the script against **our** page registry (473 entries), and the keyword file is ours -- the later OP commits that shipped regenerated indexes were not applied, since they index pages we do not have and delete our hotspot keyword. `SearchEngine`/`SearchResults` import their own module because a same-directory singleton is not visible to qmllint without it. |
| ethernet details | `op` | `10d55234` | `modules/bar/popouts/Network.qml`, `modules/nexus/pages/network/EthernetDetailPage.qml`, `modules/nexus/common/EthernetSection.qml`, `modules/nexus/pages/NetworkPage.qml`, `modules/dashboard/performance/NetworkCard.qml`, `utils/NetworkConnection.qml` | same | `adapted` | The bar popout takes OP's new list (connecting state, saved-profile ranking, scanning/empty states) with our sidebar-aware width and heading kept; the ethernet pages and section are near-clean picks. `Nmcli` gains `ensureEthernetConnection`, `getIpv6Config`, `setIpv6Config` and `hasEthernetDevice` ported from OP's service, since the detail page needs them. `NetworkConnection` keeps **our** callback-based stale-password flow (it is stricter than OP's) and only takes the pending-connection cleanup. |

### Kept deliberately

Not every unreferenced file is ours to remove. `components/misc/Ref.qml` is unused in all
three upstreams — including `caelestia` itself, since the C++ `ServiceRef` replaced it — so it
is upstream's to delete. `modules/notifications/QuickSharePrompt.qml` is the only incoming
transfer UI that exists and is kept as the design for a gap that is still open (T27). Both are
allowlisted in `hybrid/tools/dead-qml.py` with those reasons.

## Asset licensing watchlist

Imported assets that are **not** obviously original work of the fork author, to resolve before any
public release:

| Asset | Source | Status |
|---|---|---|
| `assets/shimeji/pusheen/*` (46) | `midnight` | **Accepted by the owner, 2026-09-04 — restored** and back as the `shimeji.directory` default. Pusheen remains a registered trademark of Pusheen Corp. `assets/shimeji/sparkle/` was removed with the rest of the generated set; `hybrid/tools/mascot/make-sprites.py` regenerates it, and `shimeji.directory` is a config key, so switching back is that command plus one setting. |
| `assets/bongocat.gif` | `midnight` | **Accepted by the owner, 2026-09-04 — restored** as the `paths.mediaGif` default. `assets/media-sparkle.gif` was removed; `make-gifs.py` regenerates it. |
| `assets/kurukuru.gif` | `midnight` | **Accepted by the owner, 2026-09-04 — restored** as the `paths.sessionGif` default. `assets/session-sparkle.gif` was removed; `make-gifs.py` regenerates it. |
| `assets/dino/*` (8), `assets/dino.png` | `midnight` | **Accepted by the owner, 2026-09-04 — restored.** The Chrome offline runner's T-Rex and cacti remain Google's. `components/DinoGame.qml` hardcodes sprite paths, so unlike the others this one is a code change rather than a config key; `assets/runner/` was removed; `make-game.py` regenerates it, and the paths in that file are the whole switch. |
| `assets/sounds/*` (74 files) | `midnight` | **Accepted by the owner, 2026-09-04 — restored.** Android's stock tones: Aldebaran, Altair, Antares, Betelgeuse, Beat_Box_Android and 61 more, 16 MB of Google's library. They had been replaced by 16 synthesised files; the originals are back, byte-identical, on the same reasoning as `badapple.mp4` — MiDnight publishes them already and the repository is now public. The synthesised set is not deleted, it is unshipped: `hybrid/tools/mascot/make-sounds.py` regenerates it in one command, which is the remedy if a takedown ever arrives. |
| `assets/badapple.mp4` | `midnight` | **Accepted by the owner, 2026-09-04** — kept, and published with the repo. See the section below. Touhou fan animation. It *is* the easter egg, so it cannot be substituted; the honest options are to drop the feature or to ship it without the video and let a user supply one. |
| `assets/themes/{Deadpool,Gojo,Shinchan}/*` | `op` | Not imported. Arrives with OP's theme manager in Phase 5 — **do not import the art**. |

### Original work

`assets/shimeji/sparkle/`, `assets/runner/`, `assets/media-sparkle.gif`,
`assets/session-sparkle.gif`, `assets/no-notifs.png` and (until 2026-09-04) everything under `assets/sounds/`
are made by this project and carry no third-party rights. They are generated, not hand-pixelled: `hybrid/tools/mascot/` holds
the SVG generator and the three scripts that render every frame, so the character can be
restyled or re-rendered at any size without redrawing it.

The design is deliberately not arbitrary — it is the four-pointed sparkle from
`assets/logo.svg`, in the same `#6AE5E1`, given a face. That is what makes the replacement
look like it belongs to this shell rather than like a substitute for something else.

**The sounds below are no longer what ships.** MiDnight's originals were restored on 2026-09-04
(see the watchlist row and the section above); `make-sounds.py` still regenerates the synthesised
set, and this is kept as the description of that fallback rather than of the current tree.

The sounds are additive synthesis from the standard library — no numpy, no sox, nothing to
install. Every tone is built from a fast raised-cosine attack, an exponential body and a
cosine release, so each one starts and ends at exactly zero and cannot click; the notes are
one major pentatonic scale, so no two sounds clash when they overlap. `synth.py` is the
instrument and `make-sounds.py` is the score.

**What was verified, and what was not.** Every file was checked programmatically for peak
level (0.72, headroom left deliberately), a first sample of exactly zero, negligible DC
offset, and the intended pitch via a Goertzel filter; the envelopes were rendered as
waveforms and inspected. Nobody has *listened* to them. The design choices are conventional
ones for interface sound, but if any of them is unpleasant in use, that is the check that was
not run.

GPL-3.0 covers the code. It does not launder third-party artwork that was bundled without a license.

## The repository is public, with the watchlist unresolved (2026-09-04)

The owner made this repository public on 2026-09-04 with `assets/badapple.mp4` still present and
with every other watchlist file still reachable in git history — deleting a file in a later commit
removes it from the working tree, not from the repository, and a public repo publishes history.
152 objects across `badapple.mp4`, `shimeji/pusheen/`, `bongocat.gif`, `kurukuru.gif`,
`assets/dino*` and `assets/sounds/` are therefore published.

This is recorded rather than argued. The reasoning, so a later reader does not have to reconstruct
it:

- **Forking Caelestia was never the question.** All three upstreams are GPL-3.0 and public;
  building on them is exactly what the licence is for. The watchlist has only ever been about
  third-party *media* that MiDnight bundled alongside its code.
- **The material is already public at its source.** `dim-ghub/midnight-shell` is a public GPL-3.0
  repository carrying the identical `badapple.mp4` — same 7,423,554 bytes — along with the rest.
  Republishing it here exposes nothing that is not already exposed there.
- **"Upstream does it too" is shared exposure, not a licence.** It remains true that a Touhou
  fan animation, Pusheen (a registered trademark of Pusheen Corp), Bongo Cat and Google's T-Rex
  are not GPL-3.0 and are not ours to relicense. The realistic consequence is a takedown request,
  not a lawsuit, and the remedy would be the history purge described below.
- **What was gained.** GitHub Actions is free and unlimited for public repositories. The account
  had hit its private-repo minute allowance and every CI job was refusing to start.

**If this has to be undone**, deleting the files is not enough — the paths must be purged from all
history with `git filter-repo`, which rewrites every commit SHA, breaks open PRs and diverges every
clone. Doing it while work is in flight is worse than doing it deliberately later.

**Every asset in this tree is now byte-identical to one in an upstream.** Audited rather than
assumed, in both directions: 148 files match a fork blob-for-blob, none differ, none is
unaccounted for, and nothing MiDnight ships is missing here.

The generated replacements were removed along the way -- `assets/shimeji/sparkle/`,
`assets/runner/`, `media-sparkle.gif`, `session-sparkle.gif`, `no-notifs.png` and the sixteen
synthesised sounds. Deleting them costs nothing, because the tools in `hybrid/tools/mascot/`
rebuild each set in one command, and that is the point of keeping the tools: they are the remedy
if a takedown ever arrives, not decoration.

    make-sprites.py   assets/shimeji/sparkle/     shimeji.directory
    make-gifs.py      media-/session-sparkle.gif  paths.mediaGif, paths.sessionGif
    make-idle.py      no-notifs.png               paths.noNotifsPic, paths.lockNoNotifsPic
    make-game.py      assets/runner/              hardcoded in components/DinoGame.qml
    make-sounds.py    assets/sounds/              audio.sounds.*

Four of the five are config keys. `DinoGame.qml` hardcodes its sprite paths, so that one needs an
edit -- worth knowing before it is needed rather than after.

`assets/themes/nebula/` is the exception and stays: it is a new feature's content rather than a
substitute for anything, and no fork has an equivalent.

## Phase 2/9 catch-up — `caelestia` `750e67d9..4b1dae84` (2026-09-02..2026-10-25, 102 commits)

Sync branch `sync/caelestia/2026-10-28`. Merge commit plus resolution commits; `git rerere`
recorded 85 conflict resolutions for replay. Upstream kill range and the decisions taken:

| Area (source commits) | Decision | Kind | Notes |
|---|---|---|---|
| namespace `caelestia` → `caelestia::shell` (`0b0beb52`) + CachingImage/iutils/filesystemmodel reshuffles (`35f3d210`, `e62207a3`) | taken; our files re-namespaced | `adapted` | mechanical rename over our plugin files; ours' iutils consumer state restored (imagecacher, cachingimageprovider re-added to `Images/CMakeLists.txt`; `usagefmt` to `Services/CMakeLists.txt`) |
| i18n framework (`83c72efa`, `4b1dae84`) | taken | `adapted` | ours' strings moved to `Tr.tr/trN/trCtx`; ours' extra launcher actions (Emoji/Clipboard/Windows/Keybinds/Animations) wrapped in `markCtx` |
| typed config lists (`CONFIG_GLOBAL_LIST`, `LauncherActionList`, `PlayerAliasList`, `EntryList`) | taken; ours' QML updated | `adapted` | `launcher.actions` filters read `.values`; MiDnight's per-monitor targetConfig semantics preserved on the panels |
| schema static defaults (`934c359e`-series) | taken; ours' dynamic mechanisms re-homed | `reimplemented` | preset feature/variant resolution and themed paths moved from callable defaults to static defaults + `reresolve()` on load/preset/theme change (`hybridconfig`, `userpaths`, rootnodes `detail::loaded`) |
| T62 empty-screen guard (`SETTINGS_SINGLETON_IMPL`) | re-added | `adapted` | upstream's rewrite dropped it again; two lines in `Settings/singleton.hpp`, ours' custom macro deleted |
| workspaces v2 (`f435b2c1` 系列, `124b3f6f`, `ddabf5fb`) | **not taken** | *(none)* | the recorded phase-2 decision stands: MiDnight renders workspaces itself; `Workspace/Workspaces/SpecialWorkspaces/ActiveIndicator/OccupiedBg` stay ours' whole versions; upstream's `GapMarkers.qml` removed; `perMonitor`/`showUnoccupied`/`ignoredTags` keys allowlisted in dead-config with a written reason |
| video wallpapers native (`1c406e4e`, `d6cc0d5d`, `b7959294`, `28fc7d3` previews) | **deferred (T7)** | *(none)* | upstream's C++ Visual engine renders ours obsolete once landed, but the swap touches `hybrid.features.videoWallpaper`, `WallpaperPauser`, `Wallpapers.getWallpaperThumb`, the WE workshop model and the Nexus pages; keeping the MiDnight engine for this sync and recording the stale keys (`wallpaperPlaying` toggle not offered) is the honest middle. Do the swap as its own phase. |
| clock seconds (`e54de60b`), Units service | taken; ours' dual-orientation clock kept | `adapted` | `Clock.qml` merge produced `fontFor` on ours' both layouts + `showSeconds` |
| gpu detecting flow (`c4abc387`, `90ef9e1c`) | taken | `adapted` | ours' Intel `skipNvidiaProbe` retained on upstream's setDetecting flow |
| mime video filter (`17fa999e`, filesystemmodel) | taken | `superseded` | ours' hardcoded video-extension list replaced by QMediaFormat/`QMimeDatabase` detection |
| recorder state machine | taken; ours' sounds re-added | `adapted` | `commandProc` reconcile flow from upstream; `Audio.playVideoRecord/Stop()` ours |
| nix flake inputs, CI workflows, issue templates, README (`e40cc08e` etc.) | **not taken** | *(none)* | ours owns these; upstream's image CI is the one the bootstrap script says stays off |

## Phase 2/9 catch-up — `midnight` `6c70d5cb..f4ade958` (first midnight sync, 57 non-merge commits)

First catch-up with `midnight/main` since the Phase 0 fork baseline `bb7b5657`; the 57 non-merge
commits sit on top of the merge base `6c70d5cb`, which the `caelestia` sync had already brought in.
Sync branch `sync/midnight/2026-10-28`, cut from the caelestia catch-up HEAD `047b27b3`; merge
commit plus a lint-convergence commit, `git rerere` recorded 97 conflict resolutions for replay.
Gates at the end: 411 QML files `qmllint`-clean, conventions 0, `verify --quick` GREEN.

| Area | Decision | Kind | Notes |
|---|---|---|---|
| shimeji overhaul (`Shimeji.qml`, `ShimejiSprite.qml`, `scale` key) | theirs wins | `adapted` | MiDnight rewrote both files; taken whole. `pragma ComponentBehavior: Bound` added (house style) and the sprite's bare `onGround` qualified through `root`. |
| Orion AI (`modules/sidebar/AiAssistant.qml`, sidebar `Content.qml`) | theirs wins | `adapted` | The whole AI feature arrives with its sidebar integration. Under the Bound pragma its history delegates needed explicit ids: `id: chatCard` on the sessions delegate, whose `chatId/chatIcon/chatTitle/chatPreview/chatUpdated` are delegate-local (root has no such members). ~112 section-order violations fixed. |
| GSFLoader system font probing (`modules/GSFLoader.qml`) | theirs wins | `adapted` | Font-detection logic from MiDnight replaces the static list. |
| WE state file + `updateCombinedList` (`services/Wallpapers.qml` FileView persistence) | theirs wins | `adapted` | Ours' duplicate `updateCombinedList`/`weVolume`/`weSilent` block from the conflict resolution removed; the aliases point at `weAdapter`, whose state file persists the Wallpaper-Engine side. |
| Recorder split CLI invocation (`services/Recorder.qml`), GameMode `enabled` alias, `AudioPopout`, Fastpotify (`Players.qml`) | theirs wins | `adapted` | Taken as merged. |
| wallpaper engine core (`Wallpaper.qml`, `VideoWallpaper.qml` double buffering) | **ours wins** | *(none)* | The T7 deferral stands: upstream's native C++ video engine is still the planned replacement, so MiDnight's parallel engine work is not adopted on top of ours. |
| workspaces group, Clock, dashboard/lock/utilities/News, launcher lists, WE settings block, tokens/panels pages | **ours wins** | *(none)* | Same phase-2 decisions re-applied against MiDnight's copies of the same files. |
| plugin QuickShare C++ | **ours wins** | *(none)* | Ours' plugin-side QuickShare kept; MiDnight's QML-side variant dropped with it. |
| `services/WallpaperPauser.qml` | **ours restored** | `adapted` | Consumers depend on ours' API (FileView persistence, `paused`, `hwDecoder`, `pauseOnBattery`); MiDnight's version would have silently broken them. |
| `README`, `.envrc`, nix, issue templates | **not taken** | *(none)* | D-skip as in the caelestia sync; MiDnight's `UnmaintainedNotice` deleted rather than kept. |
| union adoptions: lockconfig `session` default `true`, serviceconfig comments, aiconfig OpenRouter/OpenClaw, Players Fastpotify entry | both | `adapted` | Keys merged where both forks added disjoint members to the same config nodes. |
| `bar.github.recolourIcons` toggle (Nexus taskbar page) | **removed** | *(none)* | MiDnight added the setting and the GithubActivity consumer together; ours' GithubActivity has no recolour support, so the toggle pointed at a schema path with no reader. Delete the toggle, not the schema key. |
| `plugin/src/Caelestia/Config/barconfig.hpp` `BarSections` subobject | fixup | `adapted` | The `CONFIG_SUBOBJECT(BarSections, entries)` macro had been glued onto the tail of a comment line during conflict resolution, silently disabling it; restored on its own line. |
