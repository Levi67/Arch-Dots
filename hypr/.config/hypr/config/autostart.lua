local hl = hl or hyprland
local autostart_apps = {
    "dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP",
    -- "awww-daemon",
    "qs  --no-duplicate",
    "qs --no-duplicate --path ~/.config/quickshell/launcher.qml",
    "easyeffects --gapplication-service",
    "flatpak run me.amankhanna.opendeck --hide",
    "waypaper --restore",
    "systemctl --user start hyprpolkitagent",
    "/usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1",
    "env WEBKIT_DISABLE_DMABUF_RENDERER=1 rquickshare",
    "sh -c 'sleep 2 && hyprshade on ~/.config/hypr/shaders/vibrance.glsl'"
}

for _, cmd in ipairs(autostart_apps) do
    hl.exec_cmd(cmd)
end