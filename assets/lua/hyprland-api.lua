---@meta

-- Fallback stub of Hyprland's Lua API for lua-language-server, used only when the compositor's own
-- generated stub (/usr/share/hypr/stubs/hl.meta.lua) is not installed. Hyprland never loads this
-- file; the editor adds its directory to the language server's library path so `hl.` completes,
-- calls are checked, and `hl` is not reported as an undefined global.

---@class Hyprland
hl = {}

--- Sets an environment variable for the compositor.
---@param name string
---@param value string|number|boolean
function hl.env(name, value) end

--- Defines an animation (name, enabled, speed, bezier) or a curve preset.
---@param name string
---@param animation table
function hl.animation(name, animation) end

--- Applies a configuration table, mirroring the sections of hyprland.conf.
---@param config table<string, any>
function hl.config(config) end

--- Registers an event handler.
--- Events include "hyprland.start", "window.open", "window.close", "window.class", "window.title",
--- "window.update_rules", "workspace.active" and "monitor.added".
---@param event string
---@param callback fun(data: any)
function hl.on(event, callback) end

--- Runs a shell command once.
---@param command string
function hl.exec_cmd(command) end

--- Defines a bezier curve.
---@param name string
---@param curve { type: string, points: number[][] }
function hl.curve(name, curve) end

--- Binds a key or mouse button to a dispatcher.
---@param bind string|string[] e.g. "SUPER + Q", "mouse:278"
---@param dispatcher any
---@param options? { release?: boolean, locked?: boolean, repeating?: boolean, non_consuming?: boolean, description?: string }
function hl.bind(bind, dispatcher, options) end

-- Removes a binding made with hl.bind.
---@param bind string|string[]
function hl.unbind(bind) end

--- Dispatches immediately.
---@param dispatcher any
function hl.dispatch(dispatcher) end

--- Adds a gesture.
---@param gesture { fingers: integer, direction: string, action: any, workspace_name?: string }
function hl.gesture(gesture) end

--- Adds a monitor rule.
---@param rule { output: string, mode?: string, position?: string, scale?: number|string }
function hl.monitor(rule) end

--- Adds a window rule. Later rules win.
---@param rule table<string, any>
function hl.window_rule(rule) end

--- Adds a layer rule.
---@param rule { match: table<string, any>, [string]: any }
function hl.layer_rule(rule) end

--- Adds a workspace rule.
---@param rule table<string, any>
function hl.workspace_rule(rule) end

---@param monitor? Monitor Selects the workspace on another monitor.
---@return Workspace|nil
function hl.get_active_workspace(monitor) end

---@param monitor? Monitor
---@return Workspace|nil
function hl.get_active_special_workspace(monitor) end

---@return Monitor|nil
function hl.get_active_monitor() end

---@return Window|nil
function hl.get_active_window() end

---@return Window[]
function hl.get_windows() end

---@class Workspace
---@field id integer
---@field name string
---@field monitor Monitor
---@field special boolean

---@class Monitor
---@field name string
---@field width integer
---@field height integer

---@class Window
---@field stable_id string
---@field class string
---@field title string
---@field tags string[]
---@field workspace Workspace
---@field floating boolean
---@field fullscreen integer

-- Dispatchers ---------------------------------------------------------------------------------

hl.dsp = {}

---@class FocusArgs
---@field workspace? string|integer|Workspace
---@field window? string

---@param args FocusArgs
---@return any
function hl.dsp.focus(args) end

---@param command string
---@return any
function hl.dsp.exec_cmd(command) end

---@param name string e.g. "caelestia:launcher"
---@return any
function hl.dsp.global(name) end

---@return any
function hl.dsp.no_op() end

hl.dsp.window = {}

---@class WindowMoveArgs
---@field workspace? string|integer|Workspace
---@field follow? boolean
---@field out_of_group? boolean
---@field window? string

---@param args WindowMoveArgs
---@return any
function hl.dsp.window.move(args) end

---@param args { window?: string, action?: string }
---@return any
function hl.dsp.window.float(args) end

---@param args? { window?: string }
---@return any
function hl.dsp.window.center(args) end

---@param args? { window?: string }
---@return any
function hl.dsp.window.close(args) end

---@param args? table
---@return any
function hl.dsp.window.cycle_next(args) end

---@param args? table
---@return any
function hl.dsp.window.drag(args) end

---@param args? table
---@return any
function hl.dsp.window.fullscreen(args) end

---@param args? table
---@return any
function hl.dsp.window.pin(args) end

---@param args? table
---@return any
function hl.dsp.window.resize(args) end

---@param args? table
---@return any
function hl.dsp.window.set_prop(args) end

hl.dsp.group = {}

---@return any
function hl.dsp.group.lock() end

---@return any
function hl.dsp.group.next() end

---@return any
function hl.dsp.group.prev() end

---@return any
function hl.dsp.group.toggle() end

hl.dsp.workspace = {}

---@param name string
---@return any
function hl.dsp.workspace.toggle_special(name) end

-- Globals the dotfiles inject into the config environment.
---@type table<string, any>
vars = {}
