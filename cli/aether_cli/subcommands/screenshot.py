import subprocess
from argparse import Namespace
from datetime import datetime

from aether_cli.utils import hypr
from aether_cli.utils.notify import notify
from aether_cli.utils.paths import screenshots_cache_dir, screenshots_dir, shell_root
from aether_cli.utils.windowshot import render


class Command:
    args: Namespace

    def __init__(self, args: Namespace) -> None:
        self.args = args

    def run(self) -> None:
        if self.args.window is not None and self.args.region:
            raise ValueError("--window and --region cannot be used together")
        if self.args.clipboard and self.args.window is None:
            raise ValueError("--clipboard requires --window")
        if self.args.window is not None:
            self.window()
        elif self.args.region:
            self.region()
        else:
            self.fullscreen()

    def region(self) -> None:
        if self.args.region == "slurp":
            subprocess.run(
                ["qs", "-p", str(shell_root), "ipc", "call", "picker", "openFreeze" if self.args.freeze else "open"]
            )
        else:
            self._capture_editor(["grim", "-l", "0", "-g", self.args.region.strip(), "-"])

    def fullscreen(self) -> None:
        cmd = ["grim"]
        focused_monitor = next(monitor for monitor in hypr.message("monitors") if monitor["focused"])
        if focused_monitor:
            cmd += ["-o", focused_monitor["name"]]
        cmd += ["-"]
        self.capture(cmd, "Screenshot")

    def window(self) -> None:
        stable = self.args.window
        if stable == "active":
            active = hypr.message("activewindow")
            stable = active.get("stableId", "") if isinstance(active, dict) else ""

        if not stable:
            raise ValueError("no focused window to capture")

        framed = render(self._output(["grim", "-T", str(stable), "-"]))
        if self.args.clipboard:
            subprocess.run(["wl-copy", "--type", "image/png"], input=framed, check=False)
        else:
            self._editor(framed)

    def _capture_editor(self, cmd: list[str]) -> None:
        self._editor(self._output(cmd))

    def _editor(self, data: bytes) -> None:
        swappy = subprocess.Popen(["swappy", "-f", "-"], stdin=subprocess.PIPE, start_new_session=True)

        # Ensure stdin is not None for the type checker
        if swappy.stdin:
            swappy.stdin.write(data)
            swappy.stdin.close()

    def capture(self, cmd: list[str], label: str) -> None:
        sc_data = self._output(cmd)

        subprocess.run(["wl-copy"], input=sc_data, check=False)

        dest = screenshots_cache_dir / datetime.now().strftime("%Y%m%d%H%M%S")
        screenshots_cache_dir.mkdir(exist_ok=True, parents=True)
        dest.write_bytes(sc_data)

        action = notify(
            "-i",
            "image-x-generic-symbolic",
            "-h",
            f"STRING:image-path:{dest}",
            "--action=open=Open",
            "--action=save=Save",
            f"{label} taken",
            f"{label} stored in {dest} and copied to clipboard",
        )

        if action == "open":
            subprocess.Popen(["swappy", "-f", dest], start_new_session=True)
        elif action == "save":
            new_dest = (screenshots_dir / dest.name).with_suffix(".png")
            new_dest.parent.mkdir(exist_ok=True, parents=True)
            dest.rename(new_dest)
            notify(f"{label} saved", f"Saved to {new_dest}")

    @staticmethod
    def _output(cmd: list[str]) -> bytes:
        try:
            return subprocess.check_output(cmd)
        except subprocess.CalledProcessError as e:
            raise ValueError(f"{cmd[0]} failed with exit code {e.returncode}") from e
