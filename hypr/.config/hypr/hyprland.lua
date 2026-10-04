-- ~/.config/hypr/hyprland.lua

local hl = hl or hyprland

-- Source additional config files using Lua's pcall to prevent crashes if missing
pcall(require, "config.autostart")
pcall(require, "config.input")
pcall(require, "monitors")
pcall(require, "config.core")
pcall(require, "config.workspace_rules")
pcall(require, "config.window_layer_rules")
pcall(require, "config.keybinds")
pcall(require, "config.animations")
pcall(require, "config.nvidia")
