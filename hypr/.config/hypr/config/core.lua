local hl = hl or hyprland

hl.env("XCURSOR_SIZE", "12")
hl.env("HYPRCURSOR_SIZE", "12")
hl.env("__GL_MaxFramesAllowed", "1")

hl.config({
    cursor = {
        no_hardware_cursors = true,
    },
    general = {
        gaps_in = 5,
        gaps_out = { top = 0, right = 10, bottom = 10, left = 10 },
        border_size = 2,
        col = {},
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
        vrr = 2,
    },
    debug = {
        damage_tracking = 2,
        disable_logs = false,
    },
})

hl.device({
    name = "epic-mouse-v1",
    sensitivity = -0.5,
})
