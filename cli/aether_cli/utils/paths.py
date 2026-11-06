import hashlib
import json
import os
import shutil
import tempfile
from pathlib import Path
from typing import Any

from aether_cli.utils.io import warn

config_dir: Path = Path(os.getenv("XDG_CONFIG_HOME", Path.home() / ".config"))
data_dir: Path = Path(os.getenv("XDG_DATA_HOME", Path.home() / ".local/share"))
state_dir: Path = Path(os.getenv("XDG_STATE_HOME", Path.home() / ".local/state"))
cache_dir: Path = Path(os.getenv("XDG_CACHE_HOME", Path.home() / ".cache"))
pictures_dir: Path = Path(os.getenv("XDG_PICTURES_DIR", Path.home() / "Pictures"))
videos_dir: Path = Path(os.getenv("XDG_VIDEOS_DIR", Path.home() / "Videos"))

c_config_dir: Path = config_dir / "aether"
c_data_dir: Path = data_dir / "aether"
c_state_dir: Path = state_dir / "aether"
c_cache_dir: Path = cache_dir / "aether"


def _migrate_legacy(old: Path, new: Path) -> None:
    """Copy a pre-rename directory once. Never move: a caelestia install keeps its own."""
    if new.exists() or not old.is_dir():
        return
    try:
        # symlinks=True: copytree would otherwise follow a link to a directory, and a loop in
        # the old tree would recurse until Python gives up.
        shutil.copytree(old, new, symlinks=True)
    except (OSError, shutil.Error):
        pass


# The shell does the same migration on its first start; whichever runs first seeds the tree.
_migrate_legacy(config_dir / "caelestia", c_config_dir)
_migrate_legacy(data_dir / "caelestia", c_data_dir)
_migrate_legacy(state_dir / "caelestia", c_state_dir)

user_config_path: Path = c_config_dir / "cli.json"
cli_data_dir: Path = Path(__file__).parent.parent / "data"
templates_dir: Path = cli_data_dir / "templates"
user_templates_dir: Path = c_config_dir / "templates"
theme_dir: Path = c_state_dir / "theme"

# The checkout this package lives in: cli/aether_cli/utils/paths.py -> repo root.
shell_root: Path = Path(__file__).resolve().parents[3]
# A development checkout keeps the compiled QML module here; a packaged install has it on the
# system import path already, so this is used only when it exists.
qml_import_path: Path = shell_root / "build/qml"
hypr_scheme_path: Path = c_state_dir / "scheme/current.lua"

scheme_path: Path = c_state_dir / "scheme.json"
scheme_data_dir: Path = cli_data_dir / "schemes"
scheme_cache_dir: Path = c_cache_dir / "schemes"


def _env_path(name: str, fallback: Path) -> Path:
    """AETHER_* wins; CAELESTIA_* keeps an existing environment working."""
    return Path(os.getenv(f"AETHER_{name}", os.getenv(f"CAELESTIA_{name}", fallback)))


wallpapers_dir: Path = _env_path("WALLPAPERS_DIR", pictures_dir / "Wallpapers")
wallpaper_path_path: Path = c_state_dir / "wallpaper/path.txt"
wallpaper_link_path: Path = c_state_dir / "wallpaper/current"
wallpaper_thumbnail_path: Path = c_state_dir / "wallpaper/thumbnail.jpg"
wallpapers_cache_dir: Path = c_cache_dir / "wallpapers"

screenshots_dir: Path = _env_path("SCREENSHOTS_DIR", pictures_dir / "Screenshots")
screenshots_cache_dir: Path = c_cache_dir / "screenshots"

recordings_dir: Path = _env_path("RECORDINGS_DIR", videos_dir / "Recordings")
recording_path: Path = c_state_dir / "record/recording.mp4"
recording_notif_path: Path = c_state_dir / "record/notifid.txt"


def compute_hash(path: Path | str) -> str:
    sha = hashlib.sha256()

    with open(path, "rb") as f:
        while chunk := f.read(8192):
            sha.update(chunk)

    return sha.hexdigest()


def atomic_write(path: Path, content: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    f = tempfile.NamedTemporaryFile("w", dir=path.parent, delete=False)
    try:
        with f:
            f.write(content)
            f.flush()
            os.fsync(f.fileno())
        os.replace(f.name, path)
    except BaseException:
        os.unlink(f.name)
        raise


def atomic_dump(path: Path, content: dict[str, Any]) -> None:
    atomic_write(path, json.dumps(content))


def atomic_write_user(path: Path, content: str) -> None:
    """Write a user-owned config file, keeping the first version we replace.

    shortcut: one backup per path, never refreshed. A proper include-based theme would
    stop the overwrite altogether; upgrade if a user reports losing settings twice.
    """
    backup = path.with_name(path.name + ".aether.bak")
    try:
        if path.exists() and not backup.exists() and path.read_text() != content:
            shutil.copy2(path, backup)
    except OSError:
        pass
    atomic_write(path, content)


def get_config() -> dict[str, Any]:
    try:
        return json.loads(user_config_path.read_text())
    except json.JSONDecodeError:
        warn("failed to parse config, invalid JSON")
    except FileNotFoundError:
        pass
    return {}
