pragma ComponentBehavior: Bound

import qs.services
import qs.modules.nexus.common

// A ToggleRow bound to one key of ~/.config/caelestia/hypr-vars.lua
ToggleRow {
    id: root

    property string varKey

    showDelete: HyprVars.vars[root.varKey] !== undefined
    checked: HyprVars.vars[root.varKey] === true
    onDeleted: HyprVars.deleteVar(root.varKey)
    onToggled: HyprVars.saveVar(root.varKey, checked)
}
