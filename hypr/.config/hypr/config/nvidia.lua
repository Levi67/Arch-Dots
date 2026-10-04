-- NVIDIA-specific settings for Hyprland (RTX 4080 Super)

-- Hardware video decode via libva-nvidia-driver
hl.env("LIBVA_DRIVER_NAME", "nvidia")
hl.env("NVD_BACKEND", "direct")

-- Use the NVIDIA GLX vendor library
hl.env("__GLX_VENDOR_LIBRARY_NAME", "nvidia")

-- Keep compiled shaders in the driver cache instead of evicting them
hl.env("__GL_SHADER_DISK_CACHE_SKIP_CLEANUP", "1")

-- Optional: only enable if an app fails to start without it
-- (it has caused problems with some browsers in the past)
-- hl.env("GBM_BACKEND", "nvidia-drm")

-- Optional: only enable if you get cursor flicker or corruption
-- hl.config({
--     cursor = {
--         no_hardware_cursors = true,
--     },
-- })