// Pure-function checks for services/hyprvars.js.
// Run by tools/verify.sh: QT_QPA_PLATFORM=offscreen /usr/lib/qt6/bin/qml tests/hypr-vars.qml
import QtQuick
import "../services/hyprvars.js" as HyprVarsCode

Item {
    id: root

    property bool failed: false

    function check(name, got, want) {
        if (JSON.stringify(got) !== JSON.stringify(want)) {
            console.error("hypr-vars: " + name + " got " + JSON.stringify(got) + ", want " + JSON.stringify(want));
            root.failed = true;
        }
    }

    function parsesBack(name, source, key, want) {
        const parsed = HyprVarsCode.parseVars(source);
        check(name, HyprVarsCode.serializeVars(parsed).includes(`= ${want},`), true);
    }

    Component.onCompleted: {
        try {
            // A table that spans lines must survive a rewrite whole; the line-based parser used to
            // drop the entries and leave the file unbalanced for Hyprland to load.
            const multi = ["return {", "    kbGoToWs = {", '        "SUPER + 1",', '        "SUPER + 2"', "    },", '    terminal = "foot",', "}"].join("\n");
            const parsed = HyprVarsCode.parseVars(multi);
            check("multiline table is one value", parsed.kbGoToWs && parsed.kbGoToWs.lua.length > 0, true);
            check("multiline table keeps both binds", parsed.kbGoToWs.lua.includes("SUPER + 2"), true);
            check("key after the table is read", parsed.terminal, "foot");
            parsesBack("multiline table is written back", multi, "kbGoToWs", parsed.kbGoToWs.lua);

            // Quotes inside a string are escaped on write, or the Lua file stops parsing.
            const quoted = HyprVarsCode.parseVars('return {\n    editor = "say \\"hi\\"",\n}');
            check("quoted string parses", quoted.editor, 'say "hi"');
            check("quoted string is escaped", HyprVarsCode.serializeVars({
                editor: 'say "hi"'
            }).includes('"say \\"hi\\""'), true);

            // Types keep their type, so a number does not come back as a string.
            const typed = HyprVarsCode.parseVars('return {\n    vrr = 1,\n    blurEnabled = false,\n    cursor = "Adwaita",\n}');
            check("number stays a number", typeof typed.vrr, "number");
            check("boolean stays a boolean", typed.blurEnabled, false);
            check("string stays a string", typed.cursor, "Adwaita");

            // A value that reads a scheme colour needs the require line, or the file fails to load.
            const scheme = HyprVarsCode.serializeVars({
                activeWindowBorderColour: "rgba(scheme.primary)"
            });
            check("scheme require is added", scheme.startsWith('local scheme = require("scheme.current")'), true);
            const plain = HyprVarsCode.serializeVars({
                terminal: "foot"
            });
            check("scheme require is not added when unused", plain.startsWith("return {"), true);

            // Comments and blank lines are regenerated, and no trailing comma gets doubled.
            const tidy = HyprVarsCode.serializeVars({
                terminal: "foot",
                kbGoToWs: {
                    lua: '{\n "SUPER + 1"\n}'
                }
            });
            check("no doubled comma", tidy.includes(",,"), false);
            check("output ends with a closing brace", tidy.replace(/\s+$/, "").endsWith("}"), true);
        } catch (e) {
            console.error("hypr-vars: " + e);
            root.failed = true;
        }
        console.log(root.failed ? "hypr-vars: FAILED" : "hypr-vars: PASS");
        Qt.exit(root.failed ? 1 : 0);
    }
}
