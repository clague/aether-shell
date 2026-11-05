# `hybrid/` — project-owned code

Everything under this directory belongs to Aether. Upstream will never touch it, so it
never conflicts on a sync.

The inverse rule matters just as much: **never put project-owned files in an upstream-shaped path**
(`modules/`, `components/`, `services/`, `plugin/`, `scripts/`, `assets/`, `.github/`). Doing so
buys a guaranteed future conflict for no benefit.

```
hybrid/
├── docs/
│   ├── architecture.md            decision record — read this first
│   ├── traps.md                   the known landmines, with source evidence
│   ├── provenance.md              import ledger + asset licensing watchlist
│   ├── askpass.md                 askpass helper and its security notes
│   ├── ideas.md                   parked ideas, not built yet
│   ├── phase2-upstream-catchup.md the Phase 2 config rewrite, decision by decision
│   └── plugins.md                 the on-disk QML plugin contract
├── hypr/                          reference copy of the Hyprland config the shell writes
├── presets/                       smoke-matrix configs; picked up automatically
└── tools/
    ├── bootstrap.sh          Phase 0 — remotes, rerere, main branch, reference worktrees
    ├── upstream-status.sh    drift report across all three upstreams
    ├── smoke-matrix.sh       the verification gate: headless boot under every smoke config
    ├── dev-shell.sh          isolated dev instance; never touches the installed shell
    ├── verify.sh             build + lint + format drift + smoke presets
    ├── qml-lint.sh           qmllint over every QML file
    ├── smoke-ignore.txt      reviewed noise filter for smoke-matrix
    └── …                     focused audits (dead code, config paths, hardware)
```

## First run

The scripts may not carry an executable bit yet (the scaffold can be authored on Windows), so:

```bash
bash hybrid/tools/bootstrap.sh
chmod +x hybrid/tools/*.sh
```

After that, `./hybrid/tools/<script>.sh` works normally.

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
