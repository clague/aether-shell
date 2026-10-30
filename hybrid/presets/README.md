# Smoke presets

These files are inputs to `smoke-matrix.sh`, not a settings feature. The shell has no preset
layer: every setting has a static default, and the switch on its own Nexus page is the only
way to change it. A file here is just a `shell.json` fragment the matrix boots the shell with.

Only features that cost something when they are on -- an extra window, a decoder, a poll loop --
have a flag at all; the rest are always available and have no toggle. Four files, each with a
different job:

| File | What it sets | What it is for |
|---|---|---|
| `all-on.json` | all five features true, all variants `op` | everything instantiated at once |
| `all-off.json` | all five features false, all variants `midnight` | nothing instantiated |
| `variants-flipped.json` | mixed features, variants deliberately inconsistent | no two components agreeing |
| `theme-nebula.json` | `paths.themeName` | the only file touching a non-`hybrid` key: proves a themed path default resolves through `themeName` and falls back when it is unset |

`all-on` and `all-off` are the interesting pair: one boots with every component built at once, the
other with none of them.

Be precise about what that pair actually proves, because this file used to overclaim it. The matrix
asserts three things per run -- the shell stays up for the whole timeout, it logs no `ERROR` or
`WARN` that is not explicitly ignored, and every driven IPC call answers. **Nothing counts
instantiations.** So `all-off` proves a disabled feature does not *break* or *warn*; it does not
prove the component was never built. A feature gated with `visible: false` instead of `active:`
would pass both runs.

That the flags gate instantiation is enforced by review (see the `feature-import` skill and the
`qml-reviewer` agent), not by this harness. An instantiation census is worth building and does not
exist yet.

## Status

The `hybrid` block is real: `plugin/src/Aether/Config/hybridconfig.hpp` backs it, every key has a
schema entry, and every flag has a consumer. A key that is *not* in that schema is rejected rather
than ignored — `settings::Node` warns on unknown keys, wrong types and bad enum values, and
`smoke-matrix.sh` treats those warnings as failures.

That last part matters more than it sounds. If a file were silently accepted-and-ignored, the
matrix would boot the default config four times and report four passes. It does not, and that is
measured rather than assumed:

```
./hybrid/tools/smoke-matrix.sh --self-test
```

feeds the harness a config that is valid JSON and invalid schema, and passes only when the run
**fails**. See trap T23.

## Adding a preset

Drop a `*.json` here and `smoke-matrix.sh` picks it up automatically. Add deliberately hostile ones
— they cost seconds and catch real breakage.

Two things to know before you do:

- **A typo is now a failed run, not a quiet default.** That is the point, but it does mean a file
  has to match the compiled schema exactly. `hybrid.features.dokc` fails the matrix.
- **The variants have one implementation each until Phase 7**, so flipping them changes the config
  and not yet the shell. They are in the files anyway, because the schema and the override path
  are what is being exercised.
