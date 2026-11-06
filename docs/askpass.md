# Askpass: SSH_ASKPASS and SUDO_ASKPASS

`ssh` (passphrase prompts, `ssh-add`) and `sudo` can hand their password prompt to another
program instead of a terminal. The shell provides that program: a small helper that shows the
same kind of dialog as the polkit agent, and prints what was typed on stdout.

```
ssh / sudo ──> scripts/askpass.sh ──> caelestia:askpass IPC ──> dialog ──> stdout
```

## Setup

```sh
# Package install. A source checkout has the same file under its own tree.
export SSH_ASKPASS=/etc/xdg/quickshell/aether/scripts/askpass.sh
export SSH_ASKPASS_REQUIRE=force          # ssh ignores the helper when it still has a TTY
export SUDO_ASKPASS=/etc/xdg/quickshell/aether/scripts/askpass.sh
```

Then `sudo -A systemctl restart something`, `ssh-add`, or any `ssh` connection whose passphrase
is not in the agent will prompt in the shell. Programs that start `ssh` without a terminal (a GUI
editor pulling a git remote, `git fetch` from a launcher action) get the dialog on their own,
without `SSH_ASKPASS_REQUIRE`.

`SUDO_ASKPASS` only applies to `sudo -A`; plain `sudo` keeps using the terminal. If you want it
everywhere, wrap it (`alias sudo='sudo -A'`) or configure the terminal's own askpass.

The helper is installed next to the shell, at
`/etc/xdg/quickshell/aether/scripts/askpass.sh` (a package install) or in the repository's
`scripts/` for a source build. A symlink into `~/.local/bin` is convenient:

```sh
ln -sf /etc/xdg/quickshell/aether/scripts/askpass.sh ~/.local/bin/aether-askpass
export SSH_ASKPASS=aether-askpass SUDO_ASKPASS=aether-askpass
```

`QS=/path/to/qs` overrides the binary the helper calls, if `qs` is not on `PATH`.

## What it does

1. `qs -p <shell tree> ipc call askpass request "<prompt>"` returns a request id. The helper
   resolves `<shell tree>` from its own file (and follows the symlink above), so it does not
   depend on the shell being discoverable by config name.
2. The shell shows the dialog with that prompt, on the overlay layer, with the keyboard focused.
3. The helper polls `ipc call askpass poll <id>` every 150ms until the answer is
   `ok:<password>` (printed, exit 0) or `cancel` / `unknown` (exit 1).
4. `ipc call askpass cancel <id>` or `cancelCurrent` dismisses it from a script.

Requests queue: a second program asking while the first dialog is up waits its turn. The dialog
cancels itself after two minutes, so a helper that is killed does not leave a prompt on screen.

The IPC surface is the shell's usual one, so any script can use it:

```
caelestia:askpass request <prompt>  -> id
caelestia:askpass poll <id>         -> pending | ok:<password> | cancel | unknown
caelestia:askpass cancel <id>
caelestia:askpass cancelCurrent
```

## Why the shell and not a standalone dialog

The dialog belongs to the shell anyway: same fonts, same theme, same layer surface, and it works
over fullscreen windows. The password never touches the filesystem — it goes over the session's
IPC socket and is dropped by the shell as soon as it is collected (or after 60s if nobody comes
back for it).
