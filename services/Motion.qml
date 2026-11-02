pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Aether
import Aether.Config
import qs.services
import qs.utils
import qs.daemons

// Look & feel > Motion: one speed for the shell and Hyprland, and an option to give windows
// the same motion curves as the shell. Hyprland's own animation settings are read from
// ~/.config/hypr/hyprland/animations.lua and only changed live, never rewritten.
Singleton {
    id: root

    // Shell and Hyprland speed factor: 1 = as configured, below 1 is faster. The shell half is its
    // own `appearance.anim.durations.scale`, so it stays one setting
    readonly property real speed: GlobalConfig.appearance.anim.durations.scale
    property bool matchShell: false
    property bool touched

    // [{ leaf, enabled, speed, bezier, style }] from animations.lua
    property var base: []

    // Moves that travel get the shell's springy spatial curve, fades the soft effects curve
    readonly property var spatialLeaves: ["windowsIn", "windowsMove", "workspaces", "specialWorkspace"]
    readonly property var effectLeaves: ["windowsOut", "fade", "layers"]

    readonly property bool isDefault: !matchShell && Math.abs(speed - 1) < 0.001

    function setSpeed(factor: real): void {
        GlobalConfig.appearance.anim.durations.scale = factor;
        if (typeof GlobalConfig.save === "function")
            GlobalConfig.save();
        changed();
    }

    function setMatchShell(on: bool): void {
        matchShell = on;
        save();
        changed();
    }

    function changed(): void {
        touched = true;
        syncLater.restart();
        applyLater.restart();
    }

    function curveString(curve: var): string {
        const p = curve.bezierCurve;
        return `${p[0]}, ${p[1]}, ${p[2]}, ${p[3]}`;
    }

    // Animation preferences live in hypr-vars.lua too, so the Hyprland half survives a restart
    // instead of depending on the shell pushing it again. The curves are written as plain
    // comma-separated numbers because the override table is a flat Lua table of scalars.
    function syncVars(): void {
        const values = {
            animSpeed: Math.round(speed * 100) / 100
        };
        const removed = [];
        if (matchShell) {
            values.animMatchShell = true;
            values.animSpatialCurve = curveString(Tokens.anim.expressiveDefaultSpatial);
            values.animEffectsCurve = curveString(Tokens.anim.expressiveSlowEffects);
            values.animSpatialSpeed = Math.max(0.5, Math.round(Tokens.anim.durations.expressiveDefaultSpatial / 100 * 10) / 10);
            values.animEffectsSpeed = Math.max(0.5, Math.round(Tokens.anim.durations.expressiveSlowEffects / 100 * 10) / 10);
        } else {
            removed.push("animMatchShell", "animSpatialCurve", "animEffectsCurve", "animSpatialSpeed", "animEffectsSpeed");
        }
        HyprVars.updateVars(values, removed);
    }

    function resetAll(): void {
        matchShell = false;
        save();
        setSpeed(1);
    }

    function points(curve: var): string {
        const p = curve.bezierCurve;
        return `{ ${p[0]}, ${p[1]} }, { ${p[2]}, ${p[3]} }`;
    }

    function apply(): void {
        // Game mode turns animations off on purpose and restores itself through a reload
        if (GameMode.enabled || !Hypr.usingLua || base.length === 0 || (isDefault && !touched))
            return;
        const cmds = [];
        if (matchShell) {
            cmds.push(`eval hl.curve("shellSpatial", { type = "bezier", points = { ${points(Tokens.anim.expressiveDefaultSpatial)} } })`);
            cmds.push(`eval hl.curve("shellEffects", { type = "bezier", points = { ${points(Tokens.anim.expressiveDefaultEffects)} } })`);
        }
        for (const a of base) {
            let bezier = a.bezier;
            let spd = a.speed;
            if (matchShell && spatialLeaves.includes(a.leaf)) {
                bezier = "shellSpatial";
                spd = Tokens.anim.durations.expressiveDefaultSpatial / (GlobalConfig.appearance.anim.durations.scale || 1) / 100;
            } else if (matchShell && effectLeaves.includes(a.leaf)) {
                bezier = "shellEffects";
                spd = Tokens.anim.durations.expressiveSlowEffects / (GlobalConfig.appearance.anim.durations.scale || 1) / 100;
            }
            spd = Math.max(0.5, Math.round(spd * speed * 10) / 10);
            const style = a.style ? `, style = "${a.style}"` : "";
            cmds.push(`eval hl.animation({ leaf = "${a.leaf}", enabled = ${a.enabled}, speed = ${spd}, bezier = "${bezier}"${style} })`);
        }
        Hypr.extras.batchMessage(cmds);
    }

    function save(): void {
        stateFile.setText(JSON.stringify({
            matchShell: matchShell
        }, null, 4));
    }

    Timer {
        id: applyLater

        interval: 400
        onTriggered: root.apply()
    }

    Timer {
        id: syncLater

        interval: 250
        onTriggered: root.syncVars()
    }

    Connections {
        function onConfigReloaded(): void {
            applyLater.restart();
        }

        target: Hypr
    }

    Connections {
        function onEnabledChanged(): void {
            if (!GameMode.enabled)
                applyLater.restart();
        }

        target: GameMode
    }

    IpcHandler {
        function speed(factor: real): void {
            root.setSpeed(factor);
        }

        function matchShell(on: bool): void {
            root.setMatchShell(on);
        }

        function reset(): void {
            root.resetAll();
        }

        function status(): string {
            return JSON.stringify({
                speed: root.speed,
                matchShell: root.matchShell,
                leaves: root.base.length
            });
        }

        target: "motion"
    }

    FileView {
        id: stateFile

        path: `${Paths.state}/motion.json`
        printErrors: false
        onLoaded: {
            try {
                root.matchShell = JSON.parse(text()).matchShell === true;
            } catch (e) {
                console.warn("[motion] could not read motion.json:", e);
            }
            syncLater.restart();
            applyLater.restart();
        }
    }

    FileView {
        path: `${Paths.home}/.config/hypr/hyprland/animations.lua`
        watchChanges: true
        onFileChanged: reload()
        onLoaded: {
            // Two shapes are understood: the upstream `hl.animation({ ... })` table and the
            // helper call this tree's config uses so it can apply animSpeed/animMatchShell.
            const tableRe = /hl\.animation\(\{([^}]*)\}\)/g;
            const callRe = /animation\(\s*"([^"]+)"\s*,\s*(true|false)\s*,\s*([\d.]+)\s*,\s*"([^"]+)"(?:\s*,\s*"([^"]*)")?\s*\)/g;
            const field = (s, k) => {
                const m = s.match(new RegExp(`${k}\\s*=\\s*("([^"]*)"|[\\w.]+)`));
                return m ? (m[2] ?? m[1]) : null;
            };
            const list = [];
            let m;
            while ((m = tableRe.exec(text())) !== null) {
                const leaf = field(m[1], "leaf");
                const spd = parseFloat(field(m[1], "speed"));
                if (leaf && !isNaN(spd))
                    list.push({
                        leaf: leaf,
                        enabled: field(m[1], "enabled") !== "false",
                        speed: spd,
                        bezier: field(m[1], "bezier") ?? "default",
                        style: field(m[1], "style")
                    });
            }
            while ((m = callRe.exec(text())) !== null) {
                const spd = parseFloat(m[3]);
                if (!isNaN(spd))
                    list.push({
                        leaf: m[1],
                        enabled: m[2] !== "false",
                        speed: spd,
                        bezier: m[4],
                        style: m[5] || null
                    });
            }
            root.base = list;
            applyLater.restart();
        }
    }
}
