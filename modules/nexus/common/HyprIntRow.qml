pragma ComponentBehavior: Bound

import qs.modules.nexus.common

// A StepperRow bound to one integer key of ~/.config/caelestia/hypr-vars.lua
StepperRow {
    id: root

    property string varKey

    showDelete: HyprVars.vars[root.varKey] !== undefined
    value: HyprVars.vars[root.varKey] !== undefined ? Number(HyprVars.vars[root.varKey]) : (HyprVars.defaults[root.varKey] !== undefined ? Number(HyprVars.defaults[root.varKey]) : 0)
    onDeleted: HyprVars.deleteVar(root.varKey)
    onMoved: v => HyprVars.saveVar(root.varKey, Math.round(v))
}
