-- =============================================================================
-- HYPRLAND LUA CONFIGURATION
-- File location: ~/.config/hypr/hyprland.lua
-- =============================================================================

local hl = hl or hyprland

-- Sourced Sub-configs (Lua uses dot notation for subdirectories)
require("config.autostart")
require("config.workspaces")
require("config.input")
require("monitors")

-- -----------------------------------------------------------------------------
-- MY PROGRAMS
-- -----------------------------------------------------------------------------
local terminal = "kitty"
local fileManager = "dolphin"
local menu = "qs ipc --path ~/.config/quickshell/launcher.qml call launcher toggle"

-- -----------------------------------------------------------------------------
-- ENVIRONMENT VARIABLES & CURSOR
-- -----------------------------------------------------------------------------
hl.env("XCURSOR_SIZE", "12")
hl.env("HYPRCURSOR_SIZE", "12")
hl.env("__GL_MaxFramesAllowed", "1")

hl.config({
    cursor = {
        no_hardware_cursors = true,
    },
})

-- -----------------------------------------------------------------------------
-- LOOK AND FEEL
-- -----------------------------------------------------------------------------
hl.config({
    general = {
        gaps_in = 5,
        gaps_out = { top = 0, right = 10, bottom = 10, left = 10 },
        border_size = 2,
        col = {
            active_border = {
                colors = { "rgba(00264dff)", "rgba(0052a2ff)" },
                angle = 45,
            },
            inactive_border = "rgba(000b18aa)",
        },
        resize_on_border = true,
        allow_tearing = false,
        layout = "dwindle",
    },

    decoration = {
        rounding = 10,
        rounding_power = 2,
        active_opacity = 1.0,
        inactive_opacity = 1.0,
        shadow = {
            enabled = true,
            range = 4,
            render_power = 3,
            color = "rgba(1a1a1aee)",
        },
        blur = {
            enabled = true,
            size = 5,
            passes = 1,
            new_optimizations = true,
            xray = true,
        },
    },

    dwindle = {
        preserve_split = true,
    },

    master = {
        new_status = "master",
    },

    misc = {
        force_default_wallpaper = -1,
        disable_hyprland_logo = false,
        vrr = 1,
    },

    debug = {
        damage_tracking = 2,
        disable_logs = false,
    },
})

-- -----------------------------------------------------------------------------
-- ANIMATIONS
-- -----------------------------------------------------------------------------
hl.bezier("fluent_decel", 0, 0.2, 0.4, 1)
hl.bezier("easeOutExpo", 0.16, 1, 0.3, 1)
hl.bezier("softAcce", 0.5, 0, 0.5, 1)
hl.bezier("launcherCurve", 0.05, 0.9, 0.1, 1.05)

hl.animation("windows", 1, 2.5, "fluent_decel", "slide")
hl.animation("windowsIn", 1, 2.5, "easeOutExpo", "popin 60%")
hl.animation("windowsOut", 1, 2.5, "softAcce", "popin 80%")
hl.animation("border", 1, 10, "default")
hl.animation("fade", 1, 2.5, "default")
hl.animation("workspaces", 1, 3.5, "fluent_decel", "slide")
hl.animation("specialWorkspace", 1, 2.17, "fluent_decel", "slidevert")
hl.animation("layers", 1, 3, "launcherCurve", "slide")

-- -----------------------------------------------------------------------------
-- INPUT & DEVICES
-- -----------------------------------------------------------------------------
hl.config({
    input = {
        kb_layout = "de",
        kb_variant = "",
        kb_model = "",
        kb_options = "",
        kb_rules = "",
        follow_mouse = 1,
        sensitivity = 0,
        touchpad = {
            natural_scroll = false,
        },
    },
})

hl.device({
    name = "epic-mouse-v1",
    sensitivity = -0.5,
})

hl.device({
    name = "logitech-g502-1",
    sensitivity = -0.16,
    accel_profile = "flat",
})

hl.device({
    name = "logitech-g502-lightspeed-wireless-gaming-mouse",
    sensitivity = -0.16,
    accel_profile = "flat",
})

-- -----------------------------------------------------------------------------
-- WORKSPACE RULES
-- -----------------------------------------------------------------------------
hl.workspace(1, { monitor = "DP-3", default = true })
hl.workspace(3, { monitor = "HDMI-A-1", default = true })

hl.workspace(2, { monitor = "DP-2", default = true })
for w = 4, 10 do
    hl.workspace(w, { monitor = "DP-2" })
end

-- -----------------------------------------------------------------------------
-- AUTOSTART EXEC-ONCE
-- -----------------------------------------------------------------------------
hl.exec_once("dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP")
hl.exec_once("swww-daemon")
hl.exec_once("qs")
hl.exec_once("qs --path ~/.config/quickshell/launcher.qml")
hl.exec_once("easyeffects --gapplication-service")
hl.exec_once("flatpak run me.amankhanna.opendeck --minimized")
hl.exec_once("waypaper --restore")
hl.exec_once("systemctl --user start hyprpolkitagent")

-- -----------------------------------------------------------------------------
-- KEYBINDINGS
-- -----------------------------------------------------------------------------
local MOD = "SUPER"

-- Print Screen
hl.bind("", "Print", "exec", "hyprshot -m region --clipboard-only")

-- Menu toggle on release
hl.bindr(MOD, "SUPER_L", "exec", menu)

-- Vibrance Shader toggle
hl.bind({ MOD, "SHIFT" }, "V", "exec", "hyprshade toggle ~/.config/hypr/shaders/vibrance.glsl")

-- Window state / App launchers
hl.bind(MOD, "F", "fullscreen", "0")
hl.bind(MOD, "Return", "exec", terminal)
hl.bind(MOD, "Q", "killactive", "")
hl.bind({ MOD, "SHIFT" }, "Q", "exit", "")
hl.bind(MOD, "E", "exec", fileManager)
hl.bind(MOD, "V", "togglefloating", "")
hl.bind(MOD, "R", "exec", menu)
hl.bind(MOD, "P", "pseudo", "")
-- =============================================================================
-- HYPRLAND LUA CONFIGURATION
-- File location: ~/.config/hypr/hyprland.lua
-- =============================================================================

-- Sourced Sub-configs
require("config/autostart")
require("config/workspaces")
require("config/input")
require("monitors")

-- -----------------------------------------------------------------------------
-- MY PROGRAMS
-- -----------------------------------------------------------------------------
local terminal = "kitty"
local fileManager = "dolphin"
local menu = "qs ipc --path ~/.config/quickshell/launcher.qml call launcher toggle"

-- -----------------------------------------------------------------------------
-- ENVIRONMENT VARIABLES & CURSOR
-- -----------------------------------------------------------------------------
hl.env("XCURSOR_SIZE", "12")
hl.env("HYPRCURSOR_SIZE", "12")
hl.env("__GL_MaxFramesAllowed", "1")

hl.config({
    cursor = {
        no_hardware_cursors = true,
    },
})

-- -----------------------------------------------------------------------------
-- LOOK AND FEEL
-- -----------------------------------------------------------------------------
hl.config({
    general = {
        gaps_in = 5,
        gaps_out = { top = 0, right = 10, bottom = 10, left = 10 },
        border_size = 2,
        ["col.active_border"] = "rgba(00264dff) rgba(0052a2ff) 45deg",
        ["col.inactive_border"] = "rgba(000b18aa)",
        resize_on_border = true,
        allow_tearing = false,
        layout = "dwindle",
    },

    decoration = {
        rounding = 10,
        rounding_power = 2,
        active_opacity = 1.0,
        inactive_opacity = 1.0,
        shadow = {
            enabled = true,
            range = 4,
            render_power = 3,
            color = "rgba(1a1a1aee)",
        },
        blur = {
            enabled = true,
            size = 5,
            passes = 1,
            new_optimizations = true,
            xray = true,
        },
    },

    dwindle = {
        preserve_split = true,
    },

    master = {
        new_status = "master",
    },

    misc = {
        force_default_wallpaper = -1,
        disable_hyprland_logo = false,
        vrr = 1,
    },

    debug = {
        damage_tracking = 2,
        disable_logs = false,
    },
})

-- -----------------------------------------------------------------------------
-- ANIMATIONS
-- -----------------------------------------------------------------------------
hl.bezier("fluent_decel", 0, 0.2, 0.4, 1)
hl.bezier("easeOutExpo", 0.16, 1, 0.3, 1)
hl.bezier("softAcce", 0.5, 0, 0.5, 1)
hl.bezier("launcherCurve", 0.05, 0.9, 0.1, 1.05)

hl.animation("windows", 1, 2.5, "fluent_decel", "slide")
hl.animation("windowsIn", 1, 2.5, "easeOutExpo", "popin 60%")
hl.animation("windowsOut", 1, 2.5, "softAcce", "popin 80%")
hl.animation("border", 1, 10, "default")
hl.animation("fade", 1, 2.5, "default")
hl.animation("workspaces", 1, 3.5, "fluent_decel", "slide")
hl.animation("specialWorkspace", 1, 2.17, "fluent_decel", "slidevert")
hl.animation("layers", 1, 3, "launcherCurve", "slide")

-- -----------------------------------------------------------------------------
-- INPUT & DEVICES
-- -----------------------------------------------------------------------------
hl.config({
    input = {
        kb_layout = "de",
        kb_variant = "",
        kb_model = "",
        kb_options = "",
        kb_rules = "",
        follow_mouse = 1,
        sensitivity = 0,
        touchpad = {
            natural_scroll = false,
        },
    },
})

hl.device("epic-mouse-v1", {
    sensitivity = -0.5,
})

hl.device("logitech-g502-1", {
    sensitivity = -0.16,
    accel_profile = "flat",
})

hl.device("logitech-g502-lightspeed-wireless-gaming-mouse", {
    sensitivity = -0.16,
    accel_profile = "flat",
})

-- -----------------------------------------------------------------------------
-- WORKSPACE RULES
-- -----------------------------------------------------------------------------
hl.workspace(1, { monitor = "DP-3", default = true })
hl.workspace(3, { monitor = "HDMI-A-1", default = true })

hl.workspace(2, { monitor = "DP-2", default = true })
hl.workspace(4, { monitor = "DP-2" })
hl.workspace(5, { monitor = "DP-2" })
hl.workspace(6, { monitor = "DP-2" })
hl.workspace(7, { monitor = "DP-2" })
hl.workspace(8, { monitor = "DP-2" })
hl.workspace(9, { monitor = "DP-2" })
hl.workspace(10, { monitor = "DP-2" })

-- -----------------------------------------------------------------------------
-- AUTOSTART EXEC-ONCE
-- -----------------------------------------------------------------------------
hl.exec_once("dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP")
hl.exec_once("swww-daemon")
hl.exec_once("qs")
hl.exec_once("qs --path ~/.config/quickshell/launcher.qml")
hl.exec_once("easyeffects --gapplication-service")
hl.exec_once("flatpak run me.amankhanna.opendeck --minimized")
hl.exec_once("waypaper --restore")
hl.exec_once("systemctl --user start hyprpolkitagent")

-- -----------------------------------------------------------------------------
-- KEYBINDINGS
-- -----------------------------------------------------------------------------
local MOD = "SUPER"

-- Print Screen
hl.bind("", "Print", hl.exec("hyprshot -m region --clipboard-only"))

-- Menu toggle on release
hl.bindr(MOD, "SUPER_L", hl.exec(menu))

-- Vibrance Shader toggle
hl.bind({ MOD, "SHIFT" }, "V", hl.exec("hyprshade toggle ~/.config/hypr/shaders/vibrance.glsl"))

-- Window state / App launchers
hl.bind(MOD, "F", hl.dispatch.fullscreen, 0)
hl.bind(MOD, "Return", hl.exec(terminal))
hl.bind(MOD, "Q", hl.dispatch.killactive)
hl.bind({ MOD, "SHIFT" }, "Q", hl.dispatch.exit)
hl.bind(MOD, "E", hl.exec(fileManager))
hl.bind(MOD, "V", hl.dispatch.togglefloating)
hl.bind(MOD, "R", hl.exec(menu))
hl.bind(MOD, "P", hl.dispatch.pseudo)

-- Move focus
hl.bind(MOD, "left", hl.dispatch.movefocus, "l")
hl.bind(MOD, "right", hl.dispatch.movefocus, "r")
hl.bind(MOD, "up", hl.dispatch.movefocus, "u")
hl.bind(MOD, "down", hl.dispatch.movefocus, "d")

-- Switch Workspaces (1-10)
for i = 1, 9 do
    hl.bind(MOD, tostring(i), hl.dispatch.workspace, i)
    hl.bind({ MOD, "SHIFT" }, tostring(i), hl.dispatch.movetoworkspace, i)
end
hl.bind(MOD, "0", hl.dispatch.workspace, 10)
hl.bind({ MOD, "SHIFT" }, "0", hl.dispatch.movetoworkspace, 10)

-- Scratchpad / Special Workspace
hl.bind(MOD, "S", hl.dispatch.togglespecialworkspace, "magic")
hl.bind({ MOD, "SHIFT" }, "S", hl.dispatch.movetoworkspace, "special:magic")

-- Scroll Workspaces
hl.bind(MOD, "mouse_down", hl.dispatch.workspace, "e+1")
hl.bind(MOD, "mouse_up", hl.dispatch.workspace, "e-1")

-- Mouse Drag Window Actions
hl.bindm(MOD, "mouse:272", hl.dispatch.movewindow)
hl.bindm(MOD, "mouse:273", hl.dispatch.resizewindow)

-- Multimedia Keys (Locked & Repeat Enabled)
hl.bindel("", "XF86AudioRaiseVolume", hl.exec("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"))
hl.bindel("", "XF86AudioLowerVolume", hl.exec("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"))
hl.bindel("", "XF86AudioMute", hl.exec("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"))
hl.bindel("", "XF86AudioMicMute", hl.exec("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"))
hl.bindel("", "XF86MonBrightnessUp", hl.exec("brightnessctl -e4 -n2 set 5%+"))
hl.bindel("", "XF86MonBrightnessDown", hl.exec("brightnessctl -e4 -n2 set 5%-"))

-- Media Controls (Locked)
hl.bindl("", "XF86AudioNext", hl.exec("playerctl next"))
hl.bindl("", "XF86AudioPause", hl.exec("playerctl play-pause"))
hl.bindl("", "XF86AudioPlay", hl.exec("playerctl play-pause"))
hl.bindl("", "XF86AudioPrev", hl.exec("playerctl previous"))
-- Move focus
hl.bind(MOD, "left", "movefocus", "l")
hl.bind(MOD, "right", "movefocus", "r")
hl.bind(MOD, "up", "movefocus", "u")
hl.bind(MOD, "down", "movefocus", "d")

-- Switch Workspaces (1-10)
for i = 1, 9 do
    hl.bind(MOD, tostring(i), "workspace", tostring(i))
    hl.bind({ MOD, "SHIFT" }, tostring(i), "movetoworkspace", tostring(i))
end
hl.bind(MOD, "0", "workspace", "10")
hl.bind({ MOD, "SHIFT" }, "0", "movetoworkspace", "10")

-- Scratchpad / Special Workspace
hl.bind(MOD, "S", "togglespecialworkspace", "magic")
hl.bind({ MOD, "SHIFT" }, "S", "movetoworkspace", "special:magic")

-- Scroll Workspaces
hl.bind(MOD, "mouse_down", "workspace", "e+1")
hl.bind(MOD, "mouse_up", "workspace", "e-1")

-- Mouse Drag Window Actions
hl.bindm(MOD, "mouse:272", "movewindow", "")
hl.bindm(MOD, "mouse:273", "resizewindow", "")

-- Multimedia Keys (Locked & Repeat Enabled)
hl.bindel("", "XF86AudioRaiseVolume", "exec", "wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+")
hl.bindel("", "XF86AudioLowerVolume", "exec", "wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-")
hl.bindel("", "XF86AudioMute", "exec", "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle")
hl.bindel("", "XF86AudioMicMute", "exec", "wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle")
hl.bindel("", "XF86MonBrightnessUp", "exec", "brightnessctl -e4 -n2 set 5%+")
hl.bindel("", "XF86MonBrightnessDown", "exec", "brightnessctl -e4 -n2 set 5%-")

-- Media Controls (Locked)
hl.bindl("", "XF86AudioNext", "exec", "playerctl next")
hl.bindl("", "XF86AudioPause", "exec", "playerctl play-pause")
hl.bindl("", "XF86AudioPlay", "exec", "playerctl play-pause")
hl.bindl("", "XF86AudioPrev", "exec", "playerctl previous")