local hl = hl or hyprland
local autostart_apps = {
    "dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP",
    "awww-daemon --namespace wayland-0", -- Hier auf awww-daemon mit Namespace geändert
    "qs",
    "qs --path ~/.config/quickshell/launcher.qml",
    "easyeffects --gapplication-service",
    "flatpak run me.amankhanna.opendeck --minimized",
    "waypaper --restore",
    "systemctl --user start hyprpolkitagent",
}

for _, cmd in ipairs(autostart_apps) do
    hl.exec_cmd(cmd)
end