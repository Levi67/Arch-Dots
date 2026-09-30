local hl = hl or hyprland
local autostart_apps = {
    "dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP",
    -- "awww-daemon",
    "qs",
    "qs --path ~/.config/quickshell/launcher.qml",
    "easyeffects --gapplication-service",
    "flatpak run me.amankhanna.opendeck --minimized",
    "waypaper --restore",
    "systemctl --user start hyprpolkitagent",
    "/usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1"
}

for _, cmd in ipairs(autostart_apps) do
    hl.exec_cmd(cmd)
end