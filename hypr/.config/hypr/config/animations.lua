local hl = hl or hyprland

hl.curve("fluent_decel", { type = "bezier", points = { { 0, 0.2 }, { 0.4, 1 } } })
hl.curve("easeOutExpo", { type = "bezier", points = { { 0.16, 1 }, { 0.3, 1 } } })
hl.curve("softAcce", { type = "bezier", points = { { 0.5, 0 }, { 0.5, 1 } } })
hl.curve("launcherCurve", { type = "bezier", points = { { 0.05, 0.9 }, { 0.1, 1.05 } } })

hl.animation({ leaf = "windows", enabled = true, speed = 2.5, bezier = "fluent_decel", style = "slide" })
hl.animation({ leaf = "windowsIn", enabled = true, speed = 2.5, bezier = "easeOutExpo", style = "popin 60%" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 2.5, bezier = "softAcce", style = "popin 80%" })
hl.animation({ leaf = "border", enabled = true, speed = 10, bezier = "default" })
hl.animation({ leaf = "fade", enabled = true, speed = 2.5, bezier = "default" })
hl.animation({ leaf = "workspaces", enabled = true, speed = 3.5, bezier = "fluent_decel", style = "slide" })
hl.animation({ leaf = "specialWorkspace", enabled = true, speed = 2.17, bezier = "fluent_decel", style = "slidevert" })
hl.animation({ leaf = "layers", enabled = true, speed = 3, bezier = "launcherCurve", style = "slide" })
