local hl = hl or hyprland

local terminal = "kitty"
local fileManager = "dolphin"
local menu = "qs ipc --path ~/.config/quickshell/launcher.qml call launcher toggle"
local wallpaper = "qs ipc call wallpaper toggle"

hl.bind("SUPER + SUPER_L", hl.dsp.exec_cmd(menu), { release = true })
hl.bind("SUPER + W", hl.dsp.exec_cmd(wallpaper), { release = true })
hl.bind("SUPER + Return", hl.dsp.exec_cmd(terminal))
hl.bind("SUPER + Q", hl.dsp.window.close())
hl.bind("SUPER + SHIFT + Q", hl.dsp.exec_cmd("uwsm stop"))
hl.bind("SUPER + E", hl.dsp.exec_cmd(fileManager))
hl.bind("SUPER + V", hl.dsp.window.float({ action = "toggle" }))
hl.bind("SUPER + R", hl.dsp.exec_cmd(menu))
hl.bind("SUPER + P", hl.dsp.window.pseudo({ action = "toggle" }))
hl.bind("SUPER + J", hl.dsp.group.toggle())
hl.bind("SUPER + F", hl.dsp.window.fullscreen({ mode = "fullscreen", action = "toggle" }))

hl.bind("SUPER + SHIFT + V", hl.dsp.exec_cmd("hyprshade toggle ~/.config/hypr/shaders/vibrance.glsl"))

hl.bind("SUPER + left", hl.dsp.focus({ direction = "l" }))
hl.bind("SUPER + right", hl.dsp.focus({ direction = "r" }))
hl.bind("SUPER + up", hl.dsp.focus({ direction = "u" }))
hl.bind("SUPER + down", hl.dsp.focus({ direction = "d" }))

for i = 1, 10 do
    local key = tostring(i % 10)
    hl.bind("SUPER + " .. key, hl.dsp.focus({ workspace = tostring(i) }))
    hl.bind("SUPER + SHIFT + " .. key, hl.dsp.window.move({ workspace = tostring(i) }))
end

hl.bind("SUPER + S", hl.dsp.workspace.toggle_special("magic"))
hl.bind("SUPER + SHIFT + S", hl.dsp.window.move({ workspace = "special:magic" }))

hl.bind("SUPER + mouse:272", hl.dsp.window.drag(), { mouse = true })
hl.bind("SUPER + mouse:273", hl.dsp.window.resize(), { mouse = true })

hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"), { repeating = true, locked = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"), { repeating = true, locked = true })
hl.bind("XF86AudioMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"), { locked = true })
hl.bind("XF86AudioPlay", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioNext", hl.dsp.exec_cmd("playerctl next"), { locked = true })
hl.bind("XF86AudioPrev", hl.dsp.exec_cmd("playerctl previous"), { locked = true })
hl.bind("XF86AudioMicMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"), { locked = true })

hl.bind("Print", hl.dsp.exec_cmd("hyprshot -m region --clipboard-only -t 3000"))

