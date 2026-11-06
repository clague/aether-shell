# Project layout

Aether is no longer a thin merge of three forks. The project-owned code sits at the top level
next to the upstream-shaped tree, and the split is what keeps syncs cheap.

**Upstream-shaped paths** — `modules/`, `components/`, `services/`, `plugin/`, `scripts/`,
`assets/`, `.github/`, `shell.qml`. These are upstream's. Edit them as little as possible, and
never put a new project file there: it buys a guaranteed future merge conflict.

**Project-owned paths** — everything below this line, plus `AGENTS.md`, `README.md` and the
build files at the root:

```
bin/            the `aether` command entry point
cli/            in-tree command surface (scheme, wallpaper, record, …)
docs/           architecture, traps, provenance, plugin contract, parked ideas
hypr/           reference copy of the Hyprland config the shell depends on
presets/        smoke-matrix configs; picked up automatically
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
