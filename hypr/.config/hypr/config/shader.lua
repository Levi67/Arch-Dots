local hl = hl or hyprland

-- Vibrance shader. Hyprland drops the screen shader on every config reload
-- (e.g. when winterctl loads/unloads the snowcaps plugin), so we restore the
-- remembered state here instead of from autostart. SUPER+SHIFT+V flips it via
-- scripts/vibrance-toggle.sh, which writes "on"/"off" to the state file.
local home = os.getenv("HOME")
local shader = home .. "/.config/hypr/shaders/vibrance.glsl"
local state_file = (os.getenv("XDG_STATE_HOME") or (home .. "/.local/state")) .. "/hypr/vibrance"

local enabled = true -- default when no state saved yet
local f = io.open(state_file, "r")
if f then
    enabled = (f:read("l") or "on") ~= "off"
    f:close()
end

hl.config({ decoration = { screen_shader = enabled and shader or "" } })
