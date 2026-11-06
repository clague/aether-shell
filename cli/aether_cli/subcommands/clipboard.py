import subprocess
from argparse import Namespace


class Command:
    """Delete an entry from cliphist.

    Copying and searching the history is the launcher's job (`aether ipc launcher openClipboard`);
    only the delete flow has no launcher equivalent, and it keeps fuzzel for that one prompt.
    """

    args: Namespace

    def __init__(self, args: Namespace) -> None:
        self.args = args

    def run(self) -> None:
        clip = subprocess.check_output(["cliphist", "list"])
        chosen = subprocess.check_output(
            [
                "fuzzel",
                "--dmenu",
                "--prompt=del > ",
                "--placeholder=Delete from clipboard",
            ],
            input=clip,
        )
        subprocess.run(["cliphist", "delete"], input=chosen)
