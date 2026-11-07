"""Put Aether's Hyprland config into ~/.config/hypr.

The settings pages under Nexus > Hyprland write ~/.config/aether/hypr-vars.lua, and only this
tree's hyprland.lua reads that file. Without the tree, those pages change a file nothing loads,
so the package install leaves them doing nothing until this runs.

Entries are linked one by one, not the directory: scheme/ stays a real directory (Hyprland
writes scheme/current.lua there, and hyprmoncfg drops its monitor file next to it), and the
user's own files keep working.
"""

import shutil
import time
from argparse import Namespace
from pathlib import Path

from aether_cli.utils.io import fatal, info, log
from aether_cli.utils.paths import config_dir, shell_root

# Files and directories the tree owns.
ENTRIES = ("hyprland.lua", "variables.lua", "hyprland", "utils")
# A file inside a directory that has to stay writable.
NESTED = (("scheme", "default.lua"),)

PACKAGED = Path("/usr/share/aether-shell/hypr")


def source_tree() -> Path | None:
    for candidate in (shell_root / "hypr", PACKAGED):
        if (candidate / "hyprland.lua").is_file():
            return candidate
    return None


def target_dir() -> Path:
    return config_dir / "hypr"


def linked(dest: Path, source: Path) -> bool:
    if dest.is_symlink() and dest.resolve() == source.resolve():
        return True
    names = list(ENTRIES) + [f"{parent}/{name}" for parent, name in NESTED]
    return all(
        (dest / name).is_symlink()
        and (dest / name).resolve() == (source / name).resolve()
        for name in names
    )


def link(source: Path, dest: Path) -> None:
    if dest.is_symlink() or dest.exists():
        dest.unlink()
    dest.symlink_to(source)


class Command:
    args: Namespace

    def __init__(self, args: Namespace) -> None:
        self.args = args

    def run(self) -> None:
        source = source_tree()
        if source is None:
            fatal(
                "no Aether Hyprland config found: expected hypr/ in the checkout, or "
                "/usr/share/aether-shell/hypr from the package"
            )

        dest = target_dir()
        if linked(dest, source):
            info(f"{dest} already points at {source}")
            return

        backup = None
        if dest.exists() or dest.is_symlink():
            backup = dest.with_name(
                f"{dest.name}.aether-backup.{time.strftime('%Y%m%d-%H%M%S')}"
            )
            dest.rename(backup)
            log(f"moved your old config to {backup}")

        dest.mkdir(parents=True, exist_ok=True)
        for name in ENTRIES:
            link(source / name, dest / name)
        for parent, name in NESTED:
            (dest / parent).mkdir(exist_ok=True)
            link(source / parent / name, dest / parent / name)

        # Hyprland reads the current colours from the state directory, but it falls back to
        # ~/.config/hypr/scheme/current.lua on a machine that had them here.
        old_scheme = backup / "scheme" / "current.lua" if backup else None
        if old_scheme and old_scheme.is_file():
            shutil.copy2(old_scheme, dest / "scheme" / "current.lua")

        info(f"linked {dest} to {source}")
        if backup:
            info(f"your previous config is kept at {backup}")
            info(
                "move anything you still need into ~/.config/aether/hypr-user.lua, then delete the backup"
            )
        info("log out and back in (or restart Hyprland) to load it")
