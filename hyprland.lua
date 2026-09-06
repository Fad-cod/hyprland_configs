-- Config Hyprland en Lua (remplace hyprland.conf)
-- Charge la base ambxst puis les modules locaux dans l'ordre du .conf d'origine.

local home = os.getenv("HOME")
local hyprDir = home .. "/.config/hypr"
local hlDir = home .. "/.config/hypr/hyprland"

local function sourceFile(path)
    local fn, err = loadfile(path)
    if not fn then
        error(err, 0)
    end
    return fn()
end

-- Ambxst base config (keybinds, général, décorations, animations, layer rules)
sourceFile(home .. "/.local/share/ambxst/hyprland.lua")

-- Keyboard layout (override ambxst)
hl.config({ input = { kb_layout = "fr" } })

-- Variables (colours + other vars)
sourceFile(hlDir .. "/variables.lua")
sourceFile(hyprDir .. "/scheme/current.lua")
-- Default monitor conf
hl.monitor({ output = "", mode = "preferred", position = "auto", scale = 1 })

-- Configs
sourceFile(hlDir .. "/env.lua")
sourceFile(hlDir .. "/general.lua")
sourceFile(hlDir .. "/input.lua")
sourceFile(hlDir .. "/misc.lua")
sourceFile(hlDir .. "/animations.lua")
sourceFile(hlDir .. "/decoration.lua")
sourceFile(hlDir .. "/group.lua")
sourceFile(hlDir .. "/execs.lua")
sourceFile(hlDir .. "/rules.lua")
sourceFile(hlDir .. "/opaque_classes.lua")
sourceFile(hlDir .. "/gestures.lua")
sourceFile(hlDir .. "/keybinds.lua")
sourceFile(hlDir .. "/scrolling.lua")
-- sourceFile(hlDir .. "/layout_bind.lua") -- désactivé : utilise layout_bind.conf avec toggle_fullscreen.sh


-- Window management (override ambxst defaults)
-- hl.bind("SUPER + ALT + F", hl.dsp.window.fullscreen({ action = "unset" })) -- déplacé dans keybinds.lua avec layout check
hl.bind("SUPER + ALT + SPACE", hl.dsp.window.float())

hl.env("MESA_SHADER_CACHE_DIR", home .. "/.cache/mesa_shader_cache")

-- CPU optimization overrides
hl.config({ decoration = { shadow = { enabled = false } } })
-- hl.config({ decoration = { blur = { passes = 1 } } }) -- désactivé : écrase les variables
