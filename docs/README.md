# Docs

| Document | What it answers |
|---|---|
| `architecture.md` | why the tree looks like this: D1-D11, the feature/variant system, merge rules |
| `traps.md` | the landmines, with source evidence; read T12-T35 before touching the harness |
| `provenance.md` | every imported file and every rejected asset |
| `phase2-upstream-catchup.md` | the upstream config rewrite, decision by decision |
| `plugins.md` | the on-disk QML plugin contract |
| `askpass.md` | the askpass helper and its security notes |
| `ideas.md` | parked ideas, not built |
| this file | directory layout and the upstream/project boundary |

## Project layout

Aether is no longer a thin merge of three forks. The project-owned code sits at the top level
next to the upstream-shaped tree, and the split is what keeps syncs cheap.

| Path | Origin | Rule |
|---|---|---|
| `modules/`, `components/`, `services/`, `daemons/`, `utils/`, `assets/`, `scripts/`, `extras/`, `.github/`, `shell.qml` | upstream / imported forks | Edit as little as possible. Upstream and imported files stay at their upstream path so a merge finds them; new *dev* tools go in `tools/`. Three runtime files are ours because QML resolves them by path: `scripts/aether-colors.py`, `scripts/askpass.sh`, `modules/sidebar/aiendpoints.js`. |
| `plugin/` | upstream layout, Aether code | New C++ modules and config nodes belong under `plugin/src/Aether/`; the module layout is fixed by Qt and by the merge. |
| `nix/`, `flake.nix`, `flake.lock` | packaging, inherited and adapted | Change together with the build; not part of the shell runtime. |
| `bin/`, `cli/`, `docs/`, `hypr/`, `tests/`, `tools/` | ours | New project-owned files go here. Upstream will never touch these. |

### The project-owned tree

```
bin/            the `aether` command entry point
cli/            in-tree command surface (scheme, wallpaper, record, …)
docs/           architecture, traps, provenance, plugin contract, parked ideas
hypr/           reference copy of the Hyprland config the shell depends on
tests/          C++ unit tests, CLI/config harnesses, fixtures, smoke-matrix presets
tools/          build/lint/smoke verification, upstream drift, dead-code audits
```

`bin/` and `cli/` are one command surface: `bin/aether` adds `cli/` to `sys.path` and
dispatches. QML calls it through `Quickshell.shellPath("bin/aether")`; Hyprland keybinds call
`aether` from `PATH` (see `tools/install-cli.sh`).

## First run

The scripts may not carry an executable bit yet (the scaffold can be authored on Windows), so:

```bash
bash tools/bootstrap.sh
chmod +x tools/*.sh
```

After that, `./tools/<script>.sh` works normally.

## Everything here only runs on Linux

Quickshell needs Qt6 and Wayland. `smoke-matrix.sh` and `dev-shell.sh` refuse to run elsewhere
rather than producing meaningless results.

## Safety

`dev-shell.sh` overrides `XDG_CONFIG_HOME`, because `configDir()` is hardcoded to
`$XDG_CONFIG_HOME/caelestia` and directory naming alone does **not** isolate a dev instance
(trap T4).

No script here kills a process, installs to a system path, or writes outside its own dev
directory. **Never run OP's `install.sh` on a development machine** — it does `killall -9
quickshell` and `rm -rf` on the target directory.
