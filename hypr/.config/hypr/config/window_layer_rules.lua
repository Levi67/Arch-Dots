local hl = hl or hyprland

hl.window_rule({ match = { class = ".*" }, suppress_event = "maximize" })
hl.window_rule({ match = { class = "^(steam_app_553850)$" }, animation = "none" })
hl.window_rule({ match = { class = "^(cs2)$" }, size = { 2560, 1440 } })
hl.window_rule({ match = { title = "Open File" }, float = true, center = true, size = { 800, 600 } })

-- For Rquickshare hidden:
hl.window_rule({
  match = { class = "^(?i)(rquickshare)$" },
  workspace = "special:rqs silent",
  float = true,
  size = { 900, 600 },
  center = true,
})

hl.layer_rule({ match = { namespace = "launcher" }, blur = true, ignore_alpha = 0.0, animation = "slide" })
hl.layer_rule({ match = { namespace = "quickshell" }, blur = true, ignore_alpha = 0.3 })
hl.layer_rule({ match = { namespace = "notifications" }, blur = true, ignore_alpha = 0.3, animation = "slide" })

-- Apps that get blur, with the window opacity for each (nil = leave opacity alone)
local blur_apps = {
    { class = "kitty",           opacity = 0.9 },
    { class = "vesktop",         opacity = 0.9 },
    { class = "codium",            opacity = 0.9  },
    { class = "md.obsidian.Obsidian",        opacity = 0.9  },
    { class = "org.kde.dolphin", opacity = 0.9  },
}

-- 1) Blur off for everything
hl.window_rule({
    match = { class = ".*" },
    no_blur = true,
})

-- 2) Blur and opacity for the listed apps
for _, app in ipairs(blur_apps) do
    local rule = {
        match = { class = "^(?i)" .. app.class .. "$" },
        no_blur = false,
    }
    if app.opacity then
        rule.opacity = tostring(app.opacity) .. " " .. tostring(app.opacity)  -- active inactive
    end
    hl.window_rule(rule)
end