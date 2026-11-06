.pragma library

// Text handling for ~/.config/aether/hypr-vars.lua, kept out of the QML singletons so
// tests/hypr-vars.qml can exercise the parser and the writer without a running shell.
//
// Two writers used to keep two copies of this: services/HyprVars.qml and the keybind page.
// They drifted (the page did not escape quotes), so both now call these functions.

// Order the file is written in. Keys outside it still survive, under "Custom".
var SCHEMA = [
    {
        cat: "Apps",
        keys: ["terminal", "browser", "editor", "fileExplorer", "audioSettings"]
    },
    {
        cat: "Keyboard",
        keys: ["kbLayout", "kbVariant", "kbOptions", "repeatRate", "repeatDelay", "numlockByDefault"]
    },
    {
        cat: "Mouse",
        keys: ["followMouse", "sensitivity", "accelProfile", "naturalScroll", "middleButtonEmulation"]
    },
    {
        cat: "Touchpad",
        keys: ["touchpadNaturalScroll", "touchpadDisableTyping", "touchpadScrollFactor"]
    },
    {
        cat: "Gestures",
        keys: ["gestureFingers", "workspaceSwipeFingers", "gestureFingersMore", "workspaceSwipeDistance", "workspaceSwipeCancelRatio", "workspaceSwipeMinSpeed", "workspaceSwipeDirLock", "workspaceSwipeDirLockThreshold", "workspaceSwipeCreateNew"]
    },
    {
        cat: "Layout",
        keys: ["layout", "scrollingFullscreenOnOneColumn", "scrollingFocusFitMethod", "scrollingColumnWidth", "scrollingFollowFocus", "scrollingFollowMinVisible", "scrollingExplicitColumnWidths"]
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
        cat: "Window behaviour",
        keys: ["allowTearing", "resizeOnBorder", "focusOnClose", "onFocusUnderFullscreen", "allowSessionLockRestore", "preserveSplit", "smartSplit", "smartResizing"]
    },
    {
        cat: "Window styling",
        keys: ["windowOpacity", "windowRounding", "windowRoundingPower", "windowBorderSize", "activeWindowBorderColour", "inactiveWindowBorderColour", "dimInactive", "dimStrength"]
    },
    {
        cat: "Glass",
        keys: ["overviewBlur", "solidTextWindows", "solidTextClasses"]
    },
    {
        cat: "Window groups",
        keys: ["groupbarFontFamily", "groupbarFontSize", "groupbarGradients", "groupbarGradientRoundOnlyEdges", "groupbarGradientRounding", "groupbarHeight", "groupbarIndicatorHeight", "groupbarGapsIn", "groupbarGapsOut", "groupbarTextColour", "groupbarActiveColour", "groupbarInactiveColour", "groupbarLockedActiveColour", "groupbarLockedInactiveColour"]
    },
    {
        cat: "Motion",
        keys: ["animSpeed", "animMatchShell", "animSpatialCurve", "animEffectsCurve", "animSpatialSpeed", "animEffectsSpeed"]
    },
    {
        cat: "Misc",
        keys: ["volumeStep", "volumeMax", "specialWsCloseAny", "forceDefaultWallpaper", "cursorTheme", "cursorSize", "sleepGestureCmd", "vrr", "disableHyprlandLogo", "focusOnActivate", "middleClickPaste", "sessionLockXray", "mouseMoveEnablesDpms", "keyPressEnablesDpms", "animateManualResizes", "animateMouseWindowdragging"]
    },
    {
        cat: "Workspaces",
        keys: ["kbMoveWinToWs", "kbMoveWinToWsGroup", "kbGoToWs", "kbGoToWsGroup", "kbNextWs", "kbPrevWs"]
    },
    {
        cat: "Window group",
        keys: ["kbWindowGroupCycleNext", "kbWindowGroupCyclePrev", "kbUngroup", "kbToggleGroup"]
    },
    {
        cat: "Window action",
        keys: ["kbMoveWindow", "kbResizeWindow", "kbWindowPip", "kbPinWindow", "kbWindowFullscreen", "kbWindowBorderedFullscreen", "kbToggleWindowFloating", "kbCloseWindow"]
    },
    {
        cat: "Special workspaces",
        keys: ["kbSpecialWs", "kbSystemMonitorWs", "kbMusicWs", "kbCommunicationWs", "kbTodoWs"]
    },
    {
        cat: "Apps (keybinds)",
        keys: ["kbTerminal", "kbBrowser", "kbEditor", "kbFileExplorer"]
    },
    {
        cat: "Misc (keybinds)",
        keys: ["kbSession", "kbShowSidebar", "kbClearNotifs", "kbShowPanels", "kbLock", "kbRestoreLock"]
    }
];

// Reads a Lua table. A value that does not close on its own line keeps every following line,
// or the next write would drop it and leave the file unbalanced for Hyprland to load.
function parseVars(content) {
    const out = {};
    if (!content)
        return out;

    const lines = content.split("\n");
    for (let i = 0; i < lines.length; i++) {
        const match = lines[i].trim().match(/^([a-zA-Z0-9_]+)\s*=\s*(.+?)\s*,?$/);
        if (!match || match[1] === "return" || match[1] === "local")
            continue;

        let val = match[2];

        if (val.startsWith("{") && !val.endsWith("}")) {
            let depth = 1;
            const parts = [val];
            while (depth > 0 && i + 1 < lines.length) {
                i++;
                parts.push(lines[i]);
                for (let c = 0; c < lines[i].length; c++) {
                    if (lines[i][c] === "{")
                        depth++;
                    else if (lines[i][c] === "}")
                        depth--;
                }
            }
            out[match[1]] = {
                lua: parts.join("\n").replace(/,\s*$/, "")
            };
            continue;
        }

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
                lua: val
            };

        out[match[1]] = val;
    }
    return out;
}

// Lua literal for one value. Parsed strings lose their quotes, so they have to be added back
// here -- including every unchanged key, or one bad write silently leaves bare identifiers
// such as `editor = zeditor` in the file and Hyprland fails to load it.
function luaValue(value) {
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

function serializeVars(vars) {
    let needsScheme = false;
    for (const key in vars) {
        if (luaValue(vars[key]).includes("scheme."))
            needsScheme = true;
    }

    let content = needsScheme ? "local scheme = require(\"scheme.current\")\n\nreturn {\n" : "return {\n";
    const written = {};

    for (const cat of SCHEMA) {
        let catHasVars = false;
        for (const key of cat.keys) {
            if (vars[key] === undefined)
                continue;
            if (!catHasVars) {
                content += "    -- " + cat.cat + "\n";
                catHasVars = true;
            }
            content += "    " + key.padEnd(26) + " = " + luaValue(vars[key]) + ",\n";
            written[key] = true;
        }
        if (catHasVars)
            content += "\n";
    }

    let customHasVars = false;
    for (const key in vars) {
        if (written[key])
            continue;
        if (!customHasVars) {
            content += "    -- Custom\n";
            customHasVars = true;
        }
        content += "    " + key.padEnd(26) + " = " + luaValue(vars[key]) + ",\n";
    }

    return content.replace(/\s+$/, "") + "\n}\n";
}
