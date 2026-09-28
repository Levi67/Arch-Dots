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
hl.config({
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
})

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
-- KORREKT:
hl.workspace_rule({ workspace = "1", monitor = "DP-1", default = true })
hl.workspace_rule({ workspace = "1", monitor = "HDMI-A-1", default = true })
hl.workspace_rule({ workspace = "2", monitor = "DP-2", default = true })
hl.workspace_rule({ workspace = "3", monitor = "DP-1" })



-- -----------------------------------------------------------------------------
-- KEYBINDINGS
-- -----------------------------------------------------------------------------
local MOD = "SUPER"

-- Quick toggle on release (SUPER-Taste loslassen öffnet das Menü)
hl.bind("SUPER_L", hl.dsp.exec_cmd(menu), { release = true })

-- Hyprshade / Shaders
hl.bind(MOD .. " + SHIFT + V", hl.dsp.exec_cmd("hyprshade toggle ~/.config/hypr/shaders/vibrance.glsl"))

-- Window State / App Launchers
hl.bind(MOD .. " + Return", hl.dsp.exec_cmd(terminal))
hl.bind(MOD .. " + Q", hl.dsp.window.close())
hl.bind(MOD .. " + SHIFT + Q", hl.dsp.exit())
hl.bind(MOD .. " + E", hl.dsp.exec_cmd(filemanager))
hl.bind(MOD .. " + V", hl.dsp.window.float())
hl.bind(MOD .. " + R", hl.dsp.exec_cmd(menu))
hl.bind(MOD .. " + P", hl.dsp.window.pseudo())