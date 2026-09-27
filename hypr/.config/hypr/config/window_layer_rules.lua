local hl = hl or hyprland

hl.window_rule({ match = { class = ".*" }, suppress_event = "maximize" })
hl.window_rule({ match = { class = "^(steam_app_553850)$" }, animation = "none" })
hl.window_rule({ match = { class = "^(cs2)$" }, size = { 2560, 1440 } })
hl.window_rule({ match = { title = "Open File" }, float = true, center = true, size = { 800, 600 } })

hl.layer_rule({ match = { namespace = "launcher" }, blur = true, ignore_alpha = 0.0, animation = "slide" })
