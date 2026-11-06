local home   = os.getenv("HOME")
local hypr   = home .. "/.config/hypr"
-- The generated colour scheme lives with the shell's state, not in the dotfiles: the shell is
-- the only writer, and ~/.config/hypr stays user-owned (D11).
local state  = (os.getenv("XDG_STATE_HOME") or home .. "/.local/state") .. "/aether"
package.path = package.path .. ";" .. home .. "/.config/aether/?.lua;" .. state .. "/?.lua"

-- Create a file if it doesn't exist, optionally with initial content
local function maybe_create(file, content)
    local f = io.open(file)

    if f then
        f:close()
        return true
    end

    f = io.open(file, "w")
    if not f then return false end

    if content then f:write(content) end
    f:close()
    return true
end

-- Copy src to dst, but only if dst doesn't already exist
local function maybe_copy(src, dst)
    local out = io.open(dst)
    if out then
        out:close()
        return
    end

    local input = io.open(src, "r")
    if not input then return end

    out = io.open(dst, "w")
    if out then
        out:write(input:read("*a"))
        out:close()
    end
    input:close()
end

-- Maybe set current colours to defaults. The old location is tried first so an upgrade
-- keeps the user's colours instead of dropping to the generic default.
os.execute('mkdir -p "' .. state .. '/scheme"')
maybe_copy(hypr .. "/scheme/current.lua", state .. "/scheme/current.lua")
maybe_copy(hypr .. "/scheme/default.lua", state .. "/scheme/current.lua")

-- User variables
local overrides = maybe_create(
    home .. "/.config/aether/hypr-vars.lua",
    "return {}\n"
) and require("hypr-vars") or {}

if type(overrides) == "table" then
    local vars = require("variables")
    for k, v in pairs(overrides) do
        vars[k] = v
    end
end

-- Default monitor conf
hl.monitor({
    output   = "",
    mode     = "preferred",
    position = "auto",
    scale    = 1,
})

-- Configs
require("hyprland.env")
require("hyprland.general")
require("hyprland.input")
require("hyprland.misc")
require("hyprland.animations")
require("hyprland.decoration")
require("hyprland.group")
require("hyprland.execs")
require("hyprland.rules")
require("hyprland.gestures")
require("hyprland.keybinds")

-- User configs
if maybe_create(home .. "/.config/aether/hypr-user.lua") then
    require("hypr-user")
end

-- Added by hyprmoncfg: its generated monitor rules load last, so nothing before this can override the applied layout.
do local path = (os.getenv("XDG_CONFIG_HOME") or os.getenv("HOME") .. "/.config") .. "/hypr/hyprmoncfg-monitors.lua"; local file = io.open(path, "r"); if file then file:close(); dofile(path) end end
