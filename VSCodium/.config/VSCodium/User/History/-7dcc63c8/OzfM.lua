-- =============================================================================
-- HYPRLAND LUA CONFIGURATION (1:1 portiert)
-- File location: ~/.config/hypr/hyprland.lua
-- =============================================================================

local hl = hl or hyprland

-- Sourced Sub-configs
require("config.autostart")
require("config.input")
require("monitors")

-- -----------------------------------------------------------------------------
-- MY PROGRAMS & VARIABLES
-- -----------------------------------------------------------------------------
local terminal = "kitty"
local fileManager = "dolphin"
local menu = "qs ipc --path ~/.config/quickshell/launcher.qml call launcher toggle"
local MOD = "SUPER"

-- -----------------------------------------------------------------------------
-- ENVIRONMENT VARIABLES & CURSOR
-- -----------------------------------------------------------------------------
hl.env("XCURSOR_SIZE", "12")
hl.env("HYPRCURSOR_SIZE", "12")
hl.env("__GL_MaxFramesAllowed", "1")

-- -----------------------------------------------------------------------------
-- MAIN CONFIG (General, Decoration, Animations, Dwindle, Misc, etc.)
-- -----------------------------------------------------------------------------
hl.config({
    cursor = {
        no_hardware_cursors = true,
    },
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
    animations = {
        enabled = true,
        bezier = {
            "fluent_decel, 0, 0.2, 0.4, 1",
            "easeOutExpo, 0.16, 1, 0.3, 1",
            "softAcce, 0.5, 0, 0.5, 1",
            "launcherCurve, 0.05, 0.9, 0.1, 1.05",
        },
        animation = {
            "windows, 1, 2.5, fluent_decel, slide",
            "windowsIn, 1, 2.5, easeOutExpo, popin 60%",
            "windowsOut, 1, 2.5, softAcce, popin 80%",
            "border, 1, 10, default",
            "fade, 1, 2.5, default",
            "workspaces, 1, 3.5, fluent_decel, slide",
            "specialWorkspace, 1, 2.17, fluent_decel, slidevert",
            "layers, 1, 3, launcherCurve, slide",
        },
    },
    dwindle = {
        pseudotile = true,
        preserve_split = true,
    },
    master = {
        new_status = "master",
    },
    misc = {
        force_default_wallpaper = -1,
        disable_hyprland_logo = false,
        vfr = true,
        vrr = 1,
    },
    debug = {
        damage_tracking = 2,
        disable_logs = false,
    }
})

-- -----------------------------------------------------------------------------
-- INPUT & DEVICES
-- -----------------------------------------------------------------------------
hl.device({
    name = "epic-mouse-v1",
    sensitivity = -0.5,
})

-- -----------------------------------------------------------------------------
-- WORKSPACE RULES
-- -----------------------------------------------------------------------------
hl.workspace_rule({ workspace = "1", monitor = "DP-4", default = true })
hl.workspace_rule({ workspace = "2", monitor = "DP-3", default = true })
hl.workspace_rule({ workspace = "3", monitor = "HDMI-A-2", default = true })
hl.workspace_rule({ workspace = "4", monitor = "DP-3", default = false })
hl.workspace_rule({ workspace = "5", monitor = "DP-3", default = false })

-- -----------------------------------------------------------------------------
-- WINDOW RULES (v2)
-- -----------------------------------------------------------------------------
hl.windowrulev2("suppressevent maximize", "class:.*")
hl.windowrulev2("nofocus", "class:^$,title:^$,xwayland:1,floating:1,fullscreen:0,pinned:0")
hl.windowrulev2("noanim", "class:^(steam_app_553850)$")
hl.windowrulev2("minsize 2560 1440", "class:^(cs2)$")

-- Launcher
hl.windowrulev2("animation slide", "class:^(launcher)$")

-- XDG Desktop Portal File Picker
hl.windowrulev2("float", "title:(Open File)")
hl.windowrulev2("center", "title:(Open File)")
hl.windowrulev2("size 800 600", "title:(Open File)")

-- -----------------------------------------------------------------------------
-- LAYER RULES
-- -----------------------------------------------------------------------------
-- Quickshell
hl.layerrule("blur", "quickshell")
hl.layerrule("ignorealpha 0.5", "quickshell")
hl.layerrule("ignorezero", "quickshell")

-- Launcher
hl.layerrule("blur", "launcher")
hl.layerrule("ignorealpha 0", "launcher")
hl.layerrule("animation slide", "launcher")

-- -----------------------------------------------------------------------------
-- KEYBINDINGS
-- -----------------------------------------------------------------------------

-- Screenshot
hl.bind("", "Print", hl.dsp.exec_cmd("hyprshot -m region --clipboard-only"))

-- Quickshell / Menu
hl.bind("SUPER_L", hl.dsp.exec_cmd(menu), { release = true })
hl.bind(MOD .. " + R", hl.dsp.exec_cmd(menu))

-- Hyprshade / Shaders
hl.bind(MOD .. " + SHIFT + V", hl.dsp.exec_cmd("hyprshade toggle ~/.config/hypr/shaders/vibrance.glsl"))

-- Window State & App Launchers
hl.bind(MOD .. " + Return", hl.dsp.exec_cmd(terminal))
hl.bind(MOD .. " + E", hl.dsp.exec_cmd(fileManager))
hl.bind(MOD .. " + Q", hl.dsp.window.close())
hl.bind(MOD .. " + SHIFT + Q", hl.dsp.exit())
hl.bind(MOD .. " + F", hl.dsp.window.fullscreen("0"))
hl.bind(MOD .. " + V", hl.dsp.window.toggle_floating())
hl.bind(MOD .. " + P", hl.dsp.window.pseudo())
hl.bind(MOD .. " + J", hl.dsp.window.togglesplit())

-- Focus Movement
hl.bind(MOD .. " + left", hl.dsp.movefocus("l"))
hl.bind(MOD .. " + right", hl.dsp.movefocus("r"))
hl.bind(MOD .. " + up", hl.dsp.movefocus("u"))
hl.bind(MOD .. " + down", hl.dsp.movefocus("d"))

-- Workspace Switching
hl.bind(MOD .. " + 1", hl.dsp.workspace("1"))
hl.bind(MOD .. " + 2", hl.dsp.workspace("2"))
hl.bind(MOD .. " + 3", hl.dsp.workspace("3"))
hl.bind(MOD .. " + 4", hl.dsp.workspace("4"))
hl.bind(MOD .. " + 5", hl.dsp.workspace("5"))
hl.bind(MOD .. " + 6", hl.dsp.workspace("6"))
hl.bind(MOD .. " + 7", hl.dsp.workspace("7"))
hl.bind(MOD .. " + 8", hl.dsp.workspace("8"))
hl.bind(MOD .. " + 9", hl.dsp.workspace("9"))
hl.bind(MOD .. " + 0", hl.dsp.workspace("10"))

-- Move Window to Workspace
hl.bind(MOD .. " + SHIFT + 1", hl.dsp.window.movetoworkspace("1"))
hl.bind(MOD .. " + SHIFT + 2", hl.dsp.window.movetoworkspace("2"))
hl.bind(MOD .. " + SHIFT + 3", hl.dsp.window.movetoworkspace("3"))
hl.bind(MOD .. " + SHIFT + 4", hl.dsp.window.movetoworkspace("4"))
hl.bind(MOD .. " + SHIFT + 5", hl.dsp.window.movetoworkspace("5"))
hl.bind(MOD .. " + SHIFT + 6", hl.dsp.window.movetoworkspace("6"))
hl.bind(MOD .. " + SHIFT + 7", hl.dsp.window.movetoworkspace("7"))
hl.bind(MOD .. " + SHIFT + 8", hl.dsp.window.movetoworkspace("8"))
hl.bind(MOD .. " + SHIFT + 9", hl.dsp.window.movetoworkspace("9"))
hl.bind(MOD .. " + SHIFT + 0", hl.dsp.window.movetoworkspace("10"))

-- Special Workspace (Scratchpad)
hl.bind(MOD .. " + S", hl.dsp.togglespecialworkspace("magic"))
hl.bind(MOD .. " + SHIFT + S", hl.dsp.window.movetoworkspace("special:magic"))

-- Mouse Workspace Scrolling
hl.bind(MOD .. " + mouse_down", hl.dsp.workspace("e+1"))
hl.bind(MOD .. " + mouse_up", hl.dsp.workspace("e-1"))

-- Mouse Move & Resize
hl.bind(MOD, "mouse:272", hl.dsp.movewindow(), { mouse = true })
hl.bind(MOD, "mouse:273", hl.dsp.resizewindow(), { mouse = true })

-- Media & Brightness Controls (Laptop)
local MEDIA_FLAGS = { locked = true, repeated = true }
hl.bind("", "XF86AudioRaiseVolume", hl.dsp.exec_cmd("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"), MEDIA_FLAGS)
hl.bind("", "XF86AudioLowerVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"), MEDIA_FLAGS)
hl.bind("", "XF86AudioMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"), MEDIA_FLAGS)
hl.bind("", "XF86AudioMicMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"), MEDIA_FLAGS)
hl.bind("", "XF86MonBrightnessUp", hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%+"), MEDIA_FLAGS)
hl.bind("", "XF86MonBrightnessDown", hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%-"), MEDIA_FLAGS)

-- Playerctl Controls
local PLAY_FLAGS = { locked = true }
hl.bind("", "XF86AudioNext", hl.dsp.exec_cmd("playerctl next"), PLAY_FLAGS)
hl.bind("", "XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), PLAY_FLAGS)
hl.bind("", "XF86AudioPlay", hl.dsp.exec_cmd("playerctl play-pause"), PLAY_FLAGS)
hl.bind("", "XF86AudioPrev", hl.dsp.exec_cmd("playerctl previous"), PLAY_FLAGS)