pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Aether
import "hyprvars.js" as HyprVarsCode

// Read/write access to ~/.config/aether/hypr-vars.lua, the override table that the Hyprland
// config requires next to its own variables. Nexus uses it from Hyprland > Variables (apps and
// misc) and from Hyprland > Window effects / Spacing & animations; the shell's own Glass, Motion
// and Density services write their preferences here too, so they survive a restart instead of
// living only in ~/.local/state.
//
// Only the values the user overrides are written; deleting a key restores the default from
// ~/.config/hypr/variables.lua.
Singleton {
    id: root

    property var vars: ({})
    property var defaults: ({})
    property bool loaded: false

    readonly property string configPath: Quickshell.env("HOME") + "/.config/aether/hypr-vars.lua"
    readonly property string defaultsPath: Quickshell.env("HOME") + "/.config/hypr/variables.lua"

    function write(currentVars: var): void {
        if (!CUtils.writeFile(root.configPath, HyprVarsCode.serializeVars(currentVars)))
            console.warn("[hypr-vars] could not write", root.configPath);
        loadVars();
    }

    // One read and one write for a batch of changes: the shell services use this so a dragged
    // slider does not rewrite the file once per key.
    function updateVars(values: var, removed: var): void {
        const current = CUtils.fileExists(root.configPath) ? HyprVarsCode.parseVars(CUtils.readFile(root.configPath)) : {};
        let changed = !CUtils.fileExists(root.configPath);
        for (const key of removed ?? []) {
            if (current[key] !== undefined) {
                delete current[key];
                changed = true;
            }
        }
        for (const key in values ?? {}) {
            if (current[key] !== values[key])
                changed = true;
            current[key] = values[key];
        }
        if (changed)
            root.write(current);
    }

    function setVars(values: var): void {
        updateVars(values, []);
    }

    function removeVars(keys: var): void {
        updateVars({}, keys);
    }

    function saveVar(key: string, value: var): void {
        // AppRow passes a desktop entry's command list; store it as one command string.
        const val = value && typeof value === "object" && typeof value.join === "function" ? value.join(" ") : value;

        const currentVars = CUtils.fileExists(root.configPath) ? HyprVarsCode.parseVars(CUtils.readFile(root.configPath)) : {};
        currentVars[key] = val;
        write(currentVars);
    }

    function deleteVar(key: string): void {
        if (!CUtils.fileExists(root.configPath))
            return;
        const currentVars = HyprVarsCode.parseVars(CUtils.readFile(root.configPath));
        if (currentVars[key] === undefined)
            return;
        delete currentVars[key];
        write(currentVars);
    }

    function loadVars(): void {
        root.defaults = HyprVarsCode.parseVars(CUtils.fileExists(root.defaultsPath) ? CUtils.readFile(root.defaultsPath) : "");
        root.vars = CUtils.fileExists(root.configPath) ? HyprVarsCode.parseVars(CUtils.readFile(root.configPath)) : {};
        root.loaded = true;
    }

    Component.onCompleted: loadVars()

    // The config can change underneath the shell (git pull, hand edit, a new default), so keep
    // the defaults shown by the settings rows in sync instead of reading them once at startup.
    FileView {
        path: root.defaultsPath
        watchChanges: true
        onFileChanged: root.loadVars()
    }

    FileView {
        path: root.configPath
        watchChanges: true
        onFileChanged: root.loadVars()
    }
}
