local autostart_apps = {
    "dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP",
    "swww-daemon",
    "qs",
    "qs --path ~/.config/quickshell/launcher.qml",
    "easyeffects --gapplication-service",
    "flatpak run me.amankhanna.opendeck --minimized",
    "waypaper --restore",
    "systemctl --user start hyprpolkitagent",
}

for _, cmd in ipairs(autostart_apps) do
    hl.exec_once(cmd)
end