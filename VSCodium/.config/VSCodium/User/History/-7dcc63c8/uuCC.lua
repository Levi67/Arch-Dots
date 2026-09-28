-- ~/.config/hypr/hyprland.lua

local hl = hl or hyprland

-- Source additional config files using Lua's pcall to prevent crashes if missing
pcall(require, "config.autostart")
pcall(require, "config.input")
pcall(require, "monitors")

-- Variables
local terminal = "kitty"
local fileManager = "dolphin"
local menu = "qs ipc --path ~/.config/quickshell/launcher.qml call launcher toggle"

-- Environment Variables
hl.env("XCURSOR_SIZE", "12")
hl.env("HYPRCURSOR_SIZE", "12")
hl.env("__GL_MaxFramesAllowed", "1")

-- -----------------------------------------------------------------------------
-- CORE CONFIGURATION
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
--            active_border = "rgba(00264dff) rgba(0052a2ff) 45deg",
--            inactive_border = "rgba(000b18aa)",
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
--        pseudotile = true,
        preserve_split = true,
    },
    master = {
        new_status = "master",
    },
    misc = {
        force_default_wallpaper = -1,
        disable_hyprland_logo = false,
--        vfr = true,
        vrr = 1,
    },
    debug = {
        damage_tracking = 2,
        disable_logs = false,
    },
})

-- Devices
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
-- WINDOW & LAYER RULES
-- -----------------------------------------------------------------------------
-- Ignore maximize requests
hl.window_rule({ match = { class = ".*" }, suppress_event = "maximize" })

-- Fix dragging issues with XWayland
--hl.window_rule({
--    match = { class = "^$", title = "^$", xwayland = true, floating = true, fullscreen = false, pinned = false },
--    no_initial_focus = true
--})

-- Application specific
hl.window_rule({ match = { class = "^(steam_app_553850)$" }, animation = "none" })
hl.window_rule({ match = { class = "^(cs2)$" }, size = {2560, 1440} })

-- XDG Open File dialogs
hl.window_rule({ match = { title = "Open File" }, float = true, center = true, size = {800, 600} })

-- Layers
--hl.layer_rule({ match = { namespace = "quickshell" }, blur = true, ignore_alpha = 0.5, ignore_zero = true })
hl.layer_rule({ match = { namespace = "launcher" }, blur = true, ignore_alpha = 0.0, animation = "slide" })

-- -----------------------------------------------------------------------------
-- KEYBINDINGS (Native Lua Dispatchers)
-- -----------------------------------------------------------------------------

-- App launchers & general
hl.bind("SUPER + SUPER_L", hl.dsp.exec_cmd(menu), { release = true })
hl.bind("SUPER + Return", hl.dsp.exec_cmd(terminal))
hl.bind("SUPER + Q", hl.dsp.window.close())
hl.bind("SUPER + SHIFT + Q", hl.dsp.exec_cmd("uwsm stop")) -- Recommended graceful shutdown instead of direct exit dispatcher
hl.bind("SUPER + E", hl.dsp.exec_cmd(fileManager))
hl.bind("SUPER + V", hl.dsp.window.float({ action = "toggle" }))
hl.bind("SUPER + R", hl.dsp.exec_cmd(menu))
hl.bind("SUPER + P", hl.dsp.window.pseudo({ action = "toggle" }))
hl.bind("SUPER + J", hl.dsp.group.toggle())
hl.bind("SUPER + F", hl.dsp.window.fullscreen({ mode = "fullscreen", action = "toggle" }))

-- Shaders
hl.bind("SUPER + SHIFT + V", hl.dsp.exec_cmd("hyprshade toggle ~/.config/hypr/shaders/vibrance.glsl"))

-- Focus movement
hl.bind("SUPER + left", hl.dsp.focus({ direction = "l" }))
hl.bind("SUPER + right", hl.dsp.focus({ direction = "r" }))
hl.bind("SUPER + up", hl.dsp.focus({ direction = "u" }))
hl.bind("SUPER + down", hl.dsp.focus({ direction = "d" }))

-- Workspaces (Generated via Lua loop)
for i = 1, 10 do
    local key = tostring(i % 10) -- maps 10 to 0
    hl.bind("SUPER + " .. key, hl.dsp.focus({ workspace = tostring(i) }))
    hl.bind("SUPER + SHIFT + " .. key, hl.dsp.window.move({ workspace = tostring(i) }))
end

-- Special workspace
hl.bind("SUPER + S", hl.dsp.workspace.toggle_special("magic"))
hl.bind("SUPER + SHIFT + S", hl.dsp.window.move({ workspace = "special:magic" }))

-- Mouse actions
hl.bind("SUPER + mouse:272", hl.dsp.window.drag(), { mouse = true })
hl.bind("SUPER + mouse:273", hl.dsp.window.resize(), { mouse = true })

-- Media & Volume
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"), { repeating = true, locked = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"), { repeating = true, locked = true })
hl.bind("XF86AudioMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"), { locked = true })
hl.bind("XF86AudioPlay", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioNext", hl.dsp.exec_cmd("playerctl next"), { locked = true })
hl.bind("XF86AudioPrev", hl.dsp.exec_cmd("playerctl previous"), { locked = true })
hl.bind("XF86AudioMicMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"), { locked = true })



-- -----------------------------------------------------------------------------
-- ANIMATIONS & CURVES (Korrektur auf "bezier"-Feld)
-- -----------------------------------------------------------------------------

-- 1. Custom Bezier Curves definieren[cite: 8]
hl.curve("fluent_decel", { type = "bezier", points = { {0, 0.2}, {0.4, 1} } })
hl.curve("easeOutExpo", { type = "bezier", points = { {0.16, 1}, {0.3, 1} } })
hl.curve("softAcce", { type = "bezier", points = { {0.5, 0}, {0.5, 1} } })
hl.curve("launcherCurve", { type = "bezier", points = { {0.05, 0.9}, {0.1, 1.05} } })

-- 2. Animations-Zweige mit "bezier" statt "curve" konfigurieren
hl.animation({ leaf = "windows", enabled = true, speed = 2.5, bezier = "fluent_decel", style = "slide" })
hl.animation({ leaf = "windowsIn", enabled = true, speed = 2.5, bezier = "easeOutExpo", style = "popin 60%" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 2.5, bezier = "softAcce", style = "popin 80%" })
hl.animation({ leaf = "border", enabled = true, speed = 10, bezier = "default" })
hl.animation({ leaf = "fade", enabled = true, speed = 2.5, bezier = "default" })
hl.animation({ leaf = "workspaces", enabled = true, speed = 3.5, bezier = "fluent_decel", style = "slide" })
hl.animation({ leaf = "specialWorkspace", enabled = true, speed = 2.17, bezier = "fluent_decel", style = "slidevert" })
hl.animation({ leaf = "layers", enabled = true, speed = 3, bezier = "launcherCurve", style = "slide" })