pragma ComponentBehavior: Bound

import QtQuick
import qs.services
import qs.modules.nexus.common

// A SliderRow bound to one key of ~/.config/aether/hypr-vars.lua. The slider itself works in
// 0-1 while the variable uses the from-to range, so the value is mapped on the way in and out.
SliderRow {
    id: root

    property string varKey
    property real from: 0
    property real to: 1
    property real step: 0.1
    property real pendingValue: 0

    function currentValue(): var {
        return HyprVars.vars[root.varKey] !== undefined ? HyprVars.vars[root.varKey] : HyprVars.defaults[root.varKey];
    }

    showDelete: HyprVars.vars[root.varKey] !== undefined
    onDeleted: HyprVars.deleteVar(root.varKey)

    value: {
        const v = root.currentValue();
        if (v === undefined)
            return 0;
        return (v - root.from) / (root.to - root.from);
    }

    valueLabel: {
        const v = root.currentValue();
        return v !== undefined ? Number(v).toFixed(root.step < 1 ? 2 : 0) : "";
    }

    Component.onDestruction: {
        if (saveTimer.running)
            HyprVars.saveVar(root.varKey, root.pendingValue);
    }

    // A drag fires onMoved once per pixel. Each save rewrites hypr-vars.lua, and the file watcher
    // then reloads it into the binding above, so the slider used to fight itself. One write per
    // pause instead.
    onMoved: v => {
        let mapped = root.from + v * (root.to - root.from);
        mapped = Math.round(mapped / root.step) * root.step;
        if (root.step >= 1)
            mapped = Math.round(mapped);
        // Limit the decimals so float noise does not end up in the config file
        root.pendingValue = Number(mapped.toFixed(root.step < 1 ? 2 : 0));
        saveTimer.restart();
    }

    Timer {
        id: saveTimer

        interval: 150
        onTriggered: HyprVars.saveVar(root.varKey, root.pendingValue)
    }
}
