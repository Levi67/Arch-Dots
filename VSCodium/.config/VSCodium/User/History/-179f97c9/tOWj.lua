-- =============================================================================
-- INPUT & PER-DEVICE CONFIGURATION
-- File: ~/.config/hypr/config/input.lua
-- =============================================================================

-- Global Input Settings
hl.config({
    input = {
        kb_layout = "de",
        kb_variant = "",
        kb_model = "",
        kb_options = "",
        kb_rules = "",

        follow_mouse = 1,
        sensitivity = 0, -- -1.0 to 1.0, 0 means no modification

        touchpad = {
            natural_scroll = false,
        },
    },
})

-- Per-Device Input Configurations
-- In Lua API, properties are passed directly inside the hl.device table
hl.device({
    name = "logitech-g502-1",
    sensitivity = -0.16,
    accel_profile = "flat",
})

hl.device({
    name = "logitech-g502-lightspeed-wireless-gaming-mouse",
    sensitivity = -0.16,
    accel_profile = "flat",
})