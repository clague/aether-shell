pragma ComponentBehavior: Bound

import qs.services
import qs.modules.nexus.common

// A ToggleRow bound to one key of ~/.config/aether/hypr-vars.lua
ToggleRow {
    id: root

    property string varKey

    showDelete: HyprVars.vars[root.varKey] !== undefined
    // Fall back to the variables.lua default the way the number rows do, otherwise every
    // default-true key (blur, session_lock_xray, ...) shows as off until it is overridden.
    checked: HyprVars.vars[root.varKey] !== undefined ? HyprVars.vars[root.varKey] === true : HyprVars.defaults[root.varKey] === true
    onDeleted: HyprVars.deleteVar(root.varKey)
    onToggled: HyprVars.saveVar(root.varKey, checked)
}
