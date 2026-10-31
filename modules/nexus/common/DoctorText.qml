pragma Singleton

import QtQuick
import Aether.I18n

// Translation bridge for the strings scripts/doctor.py emits as JSON at runtime. The literals
// below are only here so xgettext sees them: every catalog entry is a msgid that the backend
// may send. Detail templates keep %1/%2 placeholders, which format() fills in.
QtObject {
    readonly property var catalog: [
        Tr.tr("NetworkManager"),
        Tr.tr("Bluetooth service"),
        Tr.tr("Radios"),
        Tr.tr("Bluetooth pairing helper"),
        Tr.tr("Shell instances"),
        Tr.tr("Saved Wi-Fi profiles"),
        Tr.tr("Authentication prompts"),
        Tr.tr("Screen share portals"),
        Tr.tr("Audio"),
        Tr.tr("Monitor profiles"),
        Tr.tr("Recent crashes"),
        Tr.tr("Shell plugin build"),
        Tr.tr("Disk space"),
        Tr.tr("Running"),
        Tr.tr("Not running, so Wi-Fi and Ethernet are unavailable"),
        Tr.tr("Not running"),
        Tr.tr("rfkill is not available"),
        Tr.tr("Wi-Fi and Bluetooth are not blocked"),
        Tr.tr("One copy running"),
        Tr.tr("Not running, so pairing requests may not show a prompt"),
        Tr.tr("One shell running"),
        Tr.tr("Could not read profiles"),
        Tr.tr("A polkit agent is running"),
        Tr.tr("Built into the running shell"),
        Tr.tr("No polkit agent is running, so apps cannot ask for your password (mounting, system settings, some updates)"),
        Tr.tr("PipeWire and WirePlumber running"),
        Tr.tr("hyprmoncfg is not installed"),
        Tr.tr("No real display is active (only Hyprland's placeholder)"),
        Tr.tr("Layouts load at startup"),
        Tr.tr("hyprmoncfg doctor reported a problem"),
        Tr.tr("Nothing important crashed in the last 3 days"),
        Tr.tr("No local build; using the system plugin"),
        Tr.tr("The C++ source is newer than the built plugin"),
        Tr.tr("Up to date with the source"),
        Tr.tr("Hardware switch blocks: %1"),
        Tr.tr("Switched off in software: %1"),
        Tr.tr("%1 copies running; they fight over pairing requests"),
        Tr.tr("%1 shells running at once (doubled panels, double notifications)"),
        Tr.tr("%1 saved, no duplicates"),
        Tr.tr("%1 look like leftovers; you choose which to forget"),
        Tr.tr("Not running: %1. Screen sharing and file pickers will fail"),
        Tr.tr("Not running: %1"),
        Tr.tr("In the last 3 days: %1"),
        Tr.tr("%1 GB free (%2%)"),
        Tr.tr("Check failed: %1"),
        Tr.tr("sudo systemctl restart NetworkManager"),
        Tr.tr("sudo systemctl restart bluetooth"),
        Tr.tr("Check the laptop's airplane-mode key or switch"),
        Tr.tr("It starts with the shell; restart the shell to bring it back"),
        Tr.tr("Log out and back in, or kill the extra quickshell processes"),
        Tr.tr("Forget the ones you don't want. Press Keep on the ones you do, and they stop being listed."),
        Tr.tr("It is in your startup list but is not running now; it may have died or failed to start at login"),
        Tr.tr("Aether provides one; start the shell. Or install a standalone agent with sudo pacman -S polkit-gnome"),
        Tr.tr("Replug the display or use the Display page to re-enable one"),
        Tr.tr("Run `hyprmoncfg doctor` in a terminal for details"),
        Tr.tr("Dismiss once you have seen them; only newer crashes will show. `coredumpctl list` shows when each happened."),
        Tr.tr("cmake --build %1 -j%2, then restart the shell"),
        Tr.tr("Low space breaks updates and caches"),
        Tr.tr("Switch on"),
        Tr.tr("Keep one"),
        Tr.tr("Start it"),
        Tr.tr("Restart"),
        Tr.tr("Dismiss"),
        Tr.tr("Forget"),
        Tr.tr("last used %1"),
        Tr.tr("never used"),
        Tr.tr("Radios switched on"),
        Tr.tr("rfkill refused; try the airplane-mode key"),
        Tr.tr("Stopped %1 extra copies"),
        Tr.tr("That profile is no longer listed as a duplicate, so it was left alone"),
        Tr.tr("Forgot the profile"),
        Tr.tr("NetworkManager refused to delete it"),
        Tr.tr("Kept; it will not be listed again"),
        Tr.tr("The agent is not installed"),
        Tr.tr("Agent started"),
        Tr.tr("It exited right away; run it in a terminal to see why"),
        Tr.tr("Crashes dismissed"),
        Tr.tr("Restarted"),
        Tr.tr("Restart failed"),
    ]

    function format(text: string, args: var): string {
        let out = Tr.tr(text);
        if (args) {
            for (let i = 0; i < args.length; i++)
                out = out.arg(args[i]);
        }
        return out;
    }

    function title(check: var): string {
        return Tr.tr(check.title);
    }

    function detail(check: var): string {
        return check.detailKey ? format(check.detailKey, check.detailArgs) : Tr.tr(check.detail);
    }

    function hint(check: var): string {
        if (check.hintKey)
            return format(check.hintKey, check.hintArgs);
        return check.hint ? Tr.tr(check.hint) : "";
    }

    function fixLabel(check: var): string {
        return check.fixLabel ? Tr.tr(check.fixLabel) : "";
    }

    function itemSub(item: var): string {
        return item.subKey ? format(item.subKey, item.subArgs) : Tr.tr(item.sub ?? "");
    }

    function message(payload: var): string {
        return payload.messageKey ? format(payload.messageKey, payload.messageArgs) : Tr.tr(payload.message ?? "");
    }
}
