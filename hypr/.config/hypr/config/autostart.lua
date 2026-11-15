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

-- The Lua config is re-evaluated on every reload (e.g. when winterctl loads
-- the snowcaps plugin), so only run autostart once per Hyprland session.
local sig = os.getenv("HYPRLAND_INSTANCE_SIGNATURE") or "default"
local runtime = os.getenv("XDG_RUNTIME_DIR") or "/tmp"
local marker = runtime .. "/hypr/" .. sig .. "/autostart.done"

local f = io.open(marker, "r")
if f then
    f:close()
else
    for _, cmd in ipairs(autostart_apps) do
        hl.exec_cmd(cmd)
    end
    local w = io.open(marker, "w")
    if w then w:close() end
end