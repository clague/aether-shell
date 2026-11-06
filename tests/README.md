# Tests

Run everything through `tools/verify.sh`, or run one suite from the repo root:

| Command | What it covers |
|---|---|
| `./tests/plugin-test.sh [filter]` | C++ unit tests: UKEY2, beat tracker, mDNS, QuickShare frames, download names, config migration, Qt theme |
| `./tests/cli-test.sh` | `bin/aether` scheme/preview and wallpaper set/print against throwaway XDG directories |
| `./tests/config-scope-test.sh` | per-monitor config scope, offscreen |
| `./tests/settings-paths.sh` | every settings schema path is referenced by the UI, offscreen |

`config-scope/` and `config-paths/` are the minimal QML configs those two harnesses boot.
`plugin-test.sh` compiles against `build/`; run `cmake --build build` first.
