local hl = hl or hyprland
local autostart_apps = {
    "dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP",
    -- "awww-daemon",
    "qs  --no-duplicate",
    "qs --no-duplicate --path ~/.config/quickshell/popups.qml",
    "easyeffects --gapplication-service",
    "flatpak run me.amankhanna.opendeck --hide",
    "waypaper --restore",
    "systemctl --user start hyprpolkitagent",
    "/usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1",
    "env WEBKIT_DISABLE_DMABUF_RENDERER=1 rquickshare",
    "sh -c 'sleep 3 && ~/.config/winter/winterctl apply'"  -- load snow caps plugin if winter mode is on
}

-- Run once the compositor is up (WAYLAND_DISPLAY exists). Running exec_cmd
-- at top level fires during the very first config parse, before the Wayland
-- socket exists, so qs etc. die. "hyprland.start" fires once per session and
-- not on config reloads (e.g. when winterctl loads the snowcaps plugin).
hl.on("hyprland.start", function()
    for _, cmd in ipairs(autostart_apps) do
        hl.exec_cmd(cmd)
    end
end)
