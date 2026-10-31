pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Aether.Config
import Aether.I18n
import qs.services
import qs.utils

// Default fonts for apps (Look & feel > App fonts). The work is done by scripts/app-fonts.py,
// which owns one fontconfig file; apps pick the change up the next time they start.
Singleton {
    id: root

    property bool enabled
    property string sans: "Adwaita Sans"
    property string mono: "JetBrains Mono"
    property var sansChoices: []
    property var monoChoices: []
    property string nowSans
    property string nowMono
    property bool busy
    property var added: []
    property string message

    // Also give the shell's own text these fonts (its icon font is never touched)
    property bool shellToo
    property var shellOriginal: null

    // Text size. Fonts differ a lot in how big their letters are at the same nominal size, so each
    // font is scaled to look as big as the reference (Adwaita Sans, JetBrains Mono) by comparing
    // the height of its lowercase letters. `sizeAdjust` (percent) is the user's own change on top.
    readonly property string script: Quickshell.shellPath("scripts/app-fonts.py")

    // One script call at a time; later ones wait their turn
    property var queue: []

    property int sizeAdjust: 100
    readonly property real autoSans: autoFactor(sans, refSans.xHeight)
    readonly property real autoMono: autoFactor(mono, refMono.xHeight)
    readonly property real sansScale: autoSans * sizeAdjust / 100
    readonly property real monoScale: autoMono * sizeAdjust / 100

    // Qt reads the installed fonts once, when the shell starts, so a font added since then is
    // unknown to it (text falls back to another font) until the shell restarts
    readonly property bool needsRestart: {
        added.length; // re-check when the list of added fonts changes
        const known = Qt.fontFamilies();
        return enabled && (!known.includes(sans) || !known.includes(mono));
    }

    function autoFactor(family: string, refX: real): real {
        // A font Qt does not know yet is drawn as another one, so measuring it would mislead
        if (!Qt.fontFamilies().includes(family))
            return 1;
        const x = family === sans ? sansMetrics.xHeight : monoMetrics.xHeight;
        return x > 0 && refX > 0 ? Math.min(1.6, Math.max(0.8, refX / x)) : 1;
    }

    function restartShell(): void {
        // caelestia-cli is a hard dependency of this shell and `shell -r` is the supported
        // restart path. OP's tree has scripts/startup-shell.sh; this one does not, so the
        // button used to exec a missing file. Quickshell exposes no programmatic reload.
        Quickshell.execDetached(["caelestia", "shell", "-r"]);
    }

    function setSizeAdjust(percent: int): void {
        sizeAdjust = percent;
        saveState();
    }

    function refresh(): void {
        statusProc.running = true;
    }

    function turn(on: bool): void {
        if (on) {
            if (sansChoices.length === 0 || monoChoices.length === 0) {
                message = Tr.tr("No selectable fonts were found");
                return;
            }
            // The built-in defaults are not guaranteed to be installed; fall back to the first
            // choice the system actually has instead of failing inside the script.
            if (!sansChoices.includes(sans))
                sans = sansChoices[0];
            if (!monoChoices.includes(mono))
                mono = monoChoices[0];
        }
        message = "";
        run(on ? ["set", sans, mono, sansScale.toFixed(3), monoScale.toFixed(3)] : ["off"]);
    }

    function choose(newSans: string, newMono: string): void {
        sans = newSans;
        mono = newMono;
        if (enabled)
            run(["set", sans, mono, sansScale.toFixed(3), monoScale.toFixed(3)]);
        applyShell();
    }

    function addFont(path: string): void {
        run(["add", path]);
    }

    function removeFont(file: string): void {
        // A font that is in use falls back to another available choice before it disappears.
        const family = added.find(a => a.file === file)?.family;
        const newSans = family === sans ? (sansChoices.find(f => f !== family) ?? sans) : sans;
        const newMono = family === mono ? (monoChoices.find(f => f !== family) ?? mono) : mono;
        if (enabled && (newSans !== sans || newMono !== mono))
            choose(newSans, newMono);
        run(["remove", file]);
    }

    function setShellToo(on: bool): void {
        shellToo = on;
        saveState();
        applyShell();
    }

    // The shell's text styles share one family each; put them back exactly as they were when off
    function applyShell(): void {
        const f = GlobalConfig.appearance.font;
        const styles = ["headline", "title", "body", "label"];
        const sizes = ["large", "medium", "small"];
        if (enabled && shellToo) {
            if (!shellOriginal) {
                shellOriginal = {
                    headline: f.headline.family,
                    title: f.title.family,
                    body: f.body.family,
                    label: f.label.family,
                    mono: f.mono.family
                };
            }
            if (!shellOriginal.sizes) {
                shellOriginal.sizes = {};
                for (const s of styles.concat(["mono"]))
                    shellOriginal.sizes[s] = {
                        large: f[s].large.size,
                        medium: f[s].medium.size,
                        small: f[s].small.size
                    };
                saveState();
            }
            for (const s of styles) {
                f[s].family = sans;
                for (const k of sizes)
                    f[s][k].size = Math.max(8, Math.round(shellOriginal.sizes[s][k] * sansScale));
            }
            f.mono.family = mono;
            for (const k of sizes)
                f.mono[k].size = Math.max(8, Math.round(shellOriginal.sizes.mono[k] * monoScale));
        } else if (shellOriginal) {
            for (const s of styles.concat(["mono"])) {
                f[s].family = shellOriginal[s];
                for (const k of sizes)
                    if (shellOriginal.sizes)
                        f[s][k].size = shellOriginal.sizes[s][k];
            }
            shellOriginal = null;
            saveState();
        } else {
            return;
        }
        if (typeof GlobalConfig.save === "function")
            GlobalConfig.save();
    }

    function saveState(): void {
        stateFile.setText(JSON.stringify({
            shellToo: shellToo,
            sizeAdjust: sizeAdjust,
            shellOriginal: shellOriginal
        }, null, 4));
    }

    function run(args: var): void {
        queue = queue.concat([args]);
        if (!busy)
            next();
    }

    function next(): void {
        if (queue.length === 0)
            return;
        busy = true;
        setProc.command = ["python3", script].concat(queue[0]);
        queue = queue.slice(1);
        setProc.running = true;
    }

    Component.onCompleted: refresh()

    // Writes the sizes to the apps and the shell once the numbers settle
    onSansScaleChanged: rescale.restart()
    onMonoScaleChanged: rescale.restart()

    Timer {
        id: rescale

        interval: 500
        onTriggered: {
            if (root.enabled)
                root.run(["set", root.sans, root.mono, root.sansScale.toFixed(3), root.monoScale.toFixed(3)]);
            root.applyShell();
        }
    }

    FontMetrics {
        id: refSans

        font.family: "Adwaita Sans"
        font.pixelSize: 100
    }

    FontMetrics {
        id: refMono

        font.family: "JetBrains Mono"
        font.pixelSize: 100
    }

    FontMetrics {
        id: sansMetrics

        font.family: root.sans
        font.pixelSize: 100
    }

    FontMetrics {
        id: monoMetrics

        font.family: root.mono
        font.pixelSize: 100
    }

    FileView {
        id: stateFile

        path: `${Paths.state}/app-fonts.json`
        printErrors: false
        onLoaded: {
            try {
                const d = JSON.parse(text());
                root.shellOriginal = d.shellOriginal ?? null;
                // A half-written state (shellToo with no original to restore) must not apply
                // fonts to the shell: the current config may already be the modified one.
                root.shellToo = d.shellToo === true && root.shellOriginal !== null;
                root.sizeAdjust = d.sizeAdjust ?? 100;
                if (d.shellToo === true && root.shellOriginal === null)
                    root.saveState();
            } catch (e) {
                console.warn("[app-fonts] could not read app-fonts.json:", e);
            }
        }
    }

    Process {
        id: statusProc

        command: ["python3", root.script, "status"]
        stdout: StdioCollector {
            onStreamFinished: {
                const raw = text.trim();
                if (raw.length === 0)
                    return;
                try {
                    const d = JSON.parse(raw);
                    root.enabled = d.enabled;
                    root.sansChoices = d.sansChoices ?? [];
                    root.monoChoices = d.monoChoices ?? [];
                    root.nowSans = d.nowSans;
                    root.nowMono = d.nowMono;
                    root.added = d.added ?? [];
                    if (d.sans && root.sansChoices.includes(d.sans))
                        root.sans = d.sans;
                    else if (root.sansChoices.includes(root.nowSans))
                        root.sans = root.nowSans;
                    else if (root.sansChoices.length > 0 && !root.sansChoices.includes(root.sans))
                        root.sans = root.sansChoices[0];
                    if (d.mono && root.monoChoices.includes(d.mono))
                        root.mono = d.mono;
                    else if (root.monoChoices.includes(root.nowMono))
                        root.mono = root.nowMono;
                    else if (root.monoChoices.length > 0 && !root.monoChoices.includes(root.mono))
                        root.mono = root.monoChoices[0];
                    root.applyShell();
                } catch (e) {
                    console.warn("[app-fonts] status failed:", e);
                }
            }
        }
    }

    Process {
        id: setProc

        stdout: StdioCollector {
            onStreamFinished: {
                root.busy = false;
                try {
                    const d = JSON.parse(text);
                    if (d.message !== undefined)
                        root.message = d.message;
                } catch (e) {
                    // The script exits without JSON when it rejects the request; stderr below
                    // carries the reason.
                }
                if (root.queue.length > 0)
                    root.next();
                else
                    root.refresh();
            }
        }

        stderr: StdioCollector {
            onStreamFinished: {
                const msg = text.trim();
                if (msg.length > 0)
                    root.message = msg;
            }
        }
    }

    IpcHandler {
        function status(): string {
            return JSON.stringify({
                enabled: root.enabled,
                sans: root.sans,
                mono: root.mono,
                nowSans: root.nowSans,
                nowMono: root.nowMono
            });
        }

        function turn(on: bool): void {
            root.turn(on);
        }

        function choose(newSans: string, newMono: string): void {
            root.choose(newSans, newMono);
        }

        function size(percent: int): void {
            root.setSizeAdjust(percent);
        }

        function scales(): string {
            return `sans ${root.autoSans.toFixed(3)} mono ${root.autoMono.toFixed(3)} adjust ${root.sizeAdjust} -> ${root.sansScale.toFixed(3)} / ${root.monoScale.toFixed(3)}; body ${GlobalConfig.appearance.font.body.medium.size}`;
        }

        function shell(on: bool): void {
            root.setShellToo(on);
        }

        function shellFamily(): string {
            return GlobalConfig.appearance.font.body.family + " / " + GlobalConfig.appearance.font.mono.family;
        }

        target: "appfonts"
    }
}
