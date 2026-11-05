"""Command line surface for the in-tree replacement of caelestia-cli.

Only the subcommands this shell uses are kept. install/update/toggle/resizer are dropfile
management or were replaced by Hyprland Lua, and clipboard/emoji are the launcher's job.
"""

import sys
from argparse import ArgumentParser, Namespace

from aether_cli.subcommands import clipboard, record, scheme, screenshot, shell, wallpaper
from aether_cli.utils.paths import wallpapers_dir
from aether_cli.utils.scheme import get_scheme_names, scheme_variants
from aether_cli.utils.wallpaper import get_wallpaper


def parse_args() -> tuple[ArgumentParser, Namespace]:
    parser = ArgumentParser(prog="aether", description="Aether shell control")
    parser.add_argument("-v", "--version", action="store_true", help="print the checkout version")
    command = parser.add_subparsers(
        title="subcommands", description="valid subcommands", metavar="COMMAND"
    )

    shell_parser = command.add_parser("shell", help="start or message the shell")
    shell_parser.set_defaults(cls=shell.Command)
    shell_parser.add_argument(
        "message", nargs="*", help="a message to send to the shell"
    )
    shell_parser.add_argument(
        "-d", "--daemon", action="store_true", help="start the shell detached"
    )
    shell_parser.add_argument(
        "-r", "--restart", action="store_true", help="kill and restart the shell"
    )
    shell_parser.add_argument(
        "-s", "--show", action="store_true", help="print all shell IPC commands"
    )
    shell_parser.add_argument(
        "-l", "--log", action="store_true", help="print the shell log"
    )
    shell_parser.add_argument(
        "-k", "--kill", action="store_true", help="kill the shell"
    )
    shell_parser.add_argument("--log-rules", metavar="RULES", help="log rules to apply")

    scheme_parser = command.add_parser("scheme", help="manage the colour scheme")
    scheme_command = scheme_parser.add_subparsers(title="subcommands")

    listing = scheme_command.add_parser("list", help="list available schemes")
    listing.set_defaults(cls=scheme.List)
    listing.add_argument("-n", "--names", action="store_true", help="list scheme names")
    listing.add_argument(
        "-f", "--flavours", action="store_true", help="list scheme flavours"
    )
    listing.add_argument("-m", "--modes", action="store_true", help="list scheme modes")
    listing.add_argument(
        "-v", "--variants", action="store_true", help="list scheme variants"
    )

    get = scheme_command.add_parser("get", help="get scheme properties")
    get.set_defaults(cls=scheme.Get)
    get.add_argument(
        "-n", "--name", action="store_true", help="print the current scheme name"
    )
    get.add_argument(
        "-f", "--flavour", action="store_true", help="print the current scheme flavour"
    )
    get.add_argument(
        "-m", "--mode", action="store_true", help="print the current scheme mode"
    )
    get.add_argument(
        "-v", "--variant", action="store_true", help="print the current scheme variant"
    )

    preview = scheme_command.add_parser("preview", help="print a scheme without applying it")
    preview.set_defaults(cls=scheme.Preview)
    preview.add_argument("-n", "--name", choices=get_scheme_names(), help="the name of the scheme to preview")
    preview.add_argument("-f", "--flavour", help="the flavour to preview")
    preview.add_argument("-m", "--mode", choices=["dark", "light"], help="the mode to preview")
    preview.add_argument("-v", "--variant", choices=scheme_variants, help="the variant to preview")

    setter = scheme_command.add_parser("set", help="set the current scheme")
    setter.set_defaults(cls=scheme.Set)
    setter.add_argument(
        "--notify", action="store_true", help="send a notification on error"
    )
    setter.add_argument(
        "-r", "--random", action="store_true", help="switch to a random scheme"
    )
    setter.add_argument(
        "-n",
        "--name",
        choices=get_scheme_names(),
        help="the name of the scheme to switch to",
    )
    setter.add_argument("-f", "--flavour", help="the flavour to switch to")
    setter.add_argument(
        "-m", "--mode", choices=["dark", "light"], help="the mode to switch to"
    )
    setter.add_argument(
        "-v", "--variant", choices=scheme_variants, help="the variant to switch to"
    )

    shot = command.add_parser("screenshot", help="take a screenshot")
    shot.set_defaults(cls=screenshot.Command)
    shot.add_argument(
        "-r", "--region", nargs="?", const="slurp", help="take a screenshot of a region"
    )
    shot.add_argument(
        "-f",
        "--freeze",
        action="store_true",
        help="freeze the screen while selecting a region",
    )

    rec = command.add_parser("record", help="start a screen recording")
    rec.set_defaults(cls=record.Command)
    rec.add_argument("-r", "--region", nargs="?", const="slurp", help="record a region")
    rec.add_argument("-s", "--sound", action="store_true", help="record audio")
    rec.add_argument(
        "-p", "--pause", action="store_true", help="pause/resume the recording"
    )
    rec.add_argument(
        "-c",
        "--clipboard",
        action="store_true",
        help="copy recording path to clipboard",
    )

    wall = command.add_parser("wallpaper", help="manage the wallpaper")
    wall.set_defaults(cls=wallpaper.Command)
    wall.add_argument(
        "-p",
        "--print",
        nargs="?",
        const=get_wallpaper(),
        metavar="PATH",
        help="print the scheme for a wallpaper",
    )
    wall.add_argument(
        "-r",
        "--random",
        nargs="?",
        const=wallpapers_dir,
        metavar="DIR",
        help="switch to a random wallpaper",
    )
    wall.add_argument("-f", "--file", help="the path to the wallpaper to switch to")
    wall.add_argument(
        "-n", "--no-filter", action="store_true", help="do not filter by size"
    )
    wall.add_argument(
        "-t",
        "--threshold",
        default=0.8,
        help="minimum size ratio of the largest monitor",
    )
    wall.add_argument(
        "-N",
        "--no-smart",
        action="store_true",
        help="do not change the scheme mode from the wallpaper",
    )

    delete = command.add_parser("clipboard", help="delete a clipboard history entry")
    delete.set_defaults(cls=clipboard.Command)
    delete.add_argument("-d", "--delete", action="store_true", help="delete from clipboard history")

    ipc = command.add_parser("ipc", help="call a shell IPC target")
    ipc.set_defaults(cls=None)
    ipc.add_argument("target")
    ipc.add_argument("function")
    ipc.add_argument("args", nargs="*")

    args = parser.parse_args()
    if args.version:
        return parser, args
    if not hasattr(args, "cls"):
        parser.print_help(sys.stderr)
        raise SystemExit(2)
    return parser, args
