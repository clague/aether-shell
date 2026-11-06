# AUR package

`PKGBUILD` for `aether-shell-git`. It is not part of the CMake install: AUR keeps its own git
repository, so this directory is the source of truth and is copied there.

## Build and install locally

```sh
cd packaging/aur
makepkg -si
```

`makepkg` clones `https://github.com/clague/aether-shell.git`, so the package builds whatever is
pushed to the default branch. To build today's working tree instead, point `source` at it for one
run:

```sh
sed -i "s|^source=.*|source=(\"aether-shell-git::git+file://$PWD/../..\")|" PKGBUILD
makepkg -f
git checkout -- PKGBUILD
```

(Then restore the file with `git checkout -- PKGBUILD`.)

## Publish

```sh
cd packaging/aur
makepkg --printsrcinfo > .SRCINFO
git clone ssh://aur@aur.archlinux.org/aether-shell-git.git /tmp/aether-aur
cp PKGBUILD aether-shell.install .SRCINFO /tmp/aether-aur/
cd /tmp/aether-aur && git add . && git commit -m 'Initial import' && git push
```

After the first import, bump `pkgver` (or leave `pkgver()` to regenerate it) and push the new
`PKGBUILD`/`.SRCINFO` for every release.

## What the package does

- Installs the shell to `/etc/xdg/quickshell/aether`, the QML plugin to
  `/usr/lib/qt6/qml/Aether`, extras to `/usr/lib/aether`, the Qt platform theme to
  `/usr/lib/qt6/plugins/platformthemes`, and `/usr/bin/aether`.
- `aether` is a wrapper around the in-tree command surface; the installed Python needs
  `python-materialyoucolor` and `python-pillow`, both declared as dependencies.
- Ships the Hyprland reference config to `/usr/share/aether-shell/hypr` and prints the autostart
  line and keybind location after install. It never writes `~/.config/hypr`.
- Does not conflict with `caelestia-shell-git`: the system files use `aether` paths, so both
  packages can be installed. Only run one of them at a time (both answer on the `aether:*`
  IPC names and draw a bar). An existing `~/.config/caelestia` is copied once to `~/.config/aether` on first start; the old directory is left alone.
