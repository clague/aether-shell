pragma Singleton

import QtQuick
import Quickshell
import Aether

// Read/write access to ~/.config/caelestia/hypr-vars.lua, the override table that the Hyprland
// config requires next to its own variables. Nexus uses it from Hyprland > Variables (apps and
// misc) and from Hyprland > Window effects / Spacing & animations; the shell's own Glass, Motion
// and Density services write their preferences here too, so they survive a restart instead of
// living only in ~/.local/state.
//
// Only the values the user overrides are written; deleting a key restores the default from
// ~/.config/hypr/variables.lua.
QtObject {
    id: root

    property var vars: ({})
    property var defaults: ({})
    property bool loaded: false

    readonly property string configPath: Quickshell.env("HOME") + "/.config/caelestia/hypr-vars.lua"
    readonly property string defaultsPath: Quickshell.env("HOME") + "/.config/hypr/variables.lua"

    // Order in which keys are written back, grouped the way the config file reads
    readonly property var schema: [
        {
            cat: "Apps",
            keys: ["terminal", "browser", "editor", "fileExplorer", "audioSettings"]
        },
        {
            cat: "Touchpad",
            keys: ["touchpadDisableTyping", "touchScrollFactor", "gestureFingers", "workspaceSwipeFingers", "gestureFingersMore"]
        },
        {
            cat: "Blur",
            keys: ["blurEnabled", "blurSpecialWs", "blurPopups", "blurInputMethods", "blurSize", "blurPasses", "blurXray"]
        },
        {
            cat: "Shadow",
            keys: ["shadowEnabled", "shadowRange", "shadowRenderPower", "shadowColour"]
        },
        {
            cat: "Gaps",
            keys: ["workspaceGaps", "windowGapsIn", "windowGapsOut", "singleWindowGapsOut"]
        },
        {
            cat: "Window styling",
            keys: ["windowOpacity", "windowRounding", "windowBorderSize", "activeWindowBorderColour", "inactiveWindowBorderColour"]
        },
        {
            cat: "Glass",
            keys: ["overviewBlur", "solidTextWindows", "solidTextClasses"]
        },
        {
            cat: "Motion",
            keys: ["animSpeed", "animMatchShell", "animSpatialCurve", "animEffectsCurve", "animSpatialSpeed", "animEffectsSpeed"]
        },
        {
            cat: "Misc",
            keys: ["volumeStep", "cursorTheme", "cursorSize", "sleepGestureCmd"]
        }
    ]

    function parseVars(content: string): var {
        const out = {};
        if (!content)
            return out;
        const lines = content.split("\n");
        for (let i = 0; i < lines.length; i++) {
            const match = lines[i].trim().match(/^([a-zA-Z0-9_]+)\s*=\s*(.+?)\s*,?$/);
            if (!match)
                continue;
            let val = match[2];
            if (val === "true")
                val = true;
            else if (val === "false")
                val = false;
            else if (val.startsWith("\"") && val.endsWith("\""))
                val = val.substring(1, val.length - 1).replace(/\\n/g, "\n").replace(/\\"/g, "\"").replace(/\\\\/g, "\\");
            else if (/^-?[0-9]+(\.[0-9]+)?$/.test(val))
                val = parseFloat(val);
            else if (val.startsWith("{") && val.endsWith("}"))
                val = {
                    lua: val // table literal, e.g. a keybind list: written back verbatim
                };
            out[match[1]] = val;
        }
        return out;
    }

    // Lua literal for one value. Parsed strings lose their quotes, so they have to be
    // added back here -- including every unchanged key, or one bad write silently leaves
    // bare identifiers such as `editor = zeditor` in the file and Hyprland fails to load it.
    function luaValue(value: var): string {
        if (value && typeof value === "object" && typeof value.lua === "string")
            return value.lua;
        if (value && typeof value === "object" && typeof value.join === "function")
            value = value.join(" ");
        if (typeof value === "boolean")
            return value ? "true" : "false";
        if (typeof value === "number")
            return String(value);
        if (value === null || value === undefined)
            return "nil";
        return "\"" + String(value).replace(/\\/g, "\\\\").replace(/"/g, "\\\"").replace(/\n/g, "\\n") + "\"";
    }

    function serializeVars(currentVars: var): string {
        let needsScheme = false;
        for (const k in currentVars) {
            if (String(currentVars[k]).includes("scheme."))
                needsScheme = true;
        }

        let content = needsScheme ? 'local scheme = require("scheme.current")\n\nreturn {\n' : "return {\n";
        const written = {};

        for (const cat of root.schema) {
            let catHasVars = false;
            for (const key of cat.keys) {
                if (currentVars[key] === undefined)
                    continue;
                if (!catHasVars) {
                    content += "    -- " + cat.cat + "\n";
                    catHasVars = true;
                }
                content += "    " + key.padEnd(26) + " = " + root.luaValue(currentVars[key]) + ",\n";
                written[key] = true;
            }
            if (catHasVars)
                content += "\n";
        }

        let customHasVars = false;
        for (const key in currentVars) {
            if (written[key])
                continue;
            if (!customHasVars) {
                content += "    -- Custom\n";
                customHasVars = true;
            }
            content += "    " + key.padEnd(26) + " = " + root.luaValue(currentVars[key]) + ",\n";
        }

        return content.replace(/\s+$/, "") + "\n}\n";
    }

    function write(currentVars: var): void {
        if (!CUtils.writeFile(root.configPath, serializeVars(currentVars)))
            console.warn("[hypr-vars] could not write", root.configPath);
        loadVars();
    }

    // One read and one write for a batch of changes: the shell services use this so a dragged
    // slider does not rewrite the file once per key.
    function updateVars(values: var, removed: var): void {
        const current = CUtils.fileExists(root.configPath) ? parseVars(CUtils.readFile(root.configPath)) : {};
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

        const currentVars = CUtils.fileExists(root.configPath) ? parseVars(CUtils.readFile(root.configPath)) : {};
        currentVars[key] = val;
        write(currentVars);
    }

    function deleteVar(key: string): void {
        if (!CUtils.fileExists(root.configPath))
            return;
        const currentVars = parseVars(CUtils.readFile(root.configPath));
        if (currentVars[key] === undefined)
            return;
        delete currentVars[key];
        write(currentVars);
    }

    function loadVars(): void {
        root.defaults = parseVars(CUtils.fileExists(root.defaultsPath) ? CUtils.readFile(root.defaultsPath) : "");
        root.vars = CUtils.fileExists(root.configPath) ? parseVars(CUtils.readFile(root.configPath)) : {};
        root.loaded = true;
    }

    Component.onCompleted: loadVars()
}
