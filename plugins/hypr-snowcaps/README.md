# hypr-snowcaps

Hyprland plugin (0.57, Lua config) that piles cozy, cartoony snow on top of every non-fullscreen
window: a thick flat-white pillow with a few soft mounds that drapes over the rounded corners,
plus frosting drips that appear and lengthen over time. Caps start thin and grow to full height
over `grow_minutes`. They reserve no space, so the layout is untouched, and the bar or windows
stacked above cover them as usual.

The shape is drawn with cairo into a texture per window, rebuilt only when the width, scale,
corner rounding or growth step (40 steps) changes.

Part of winter mode: `~/.config/winter/winterctl` loads/unloads it (unloaded = zero cost)
and rebuilds automatically when `/usr/bin/Hyprland` is newer than `snowcaps.so`.

## Build

    make            # uses the headers shipped with the hyprland package (pkg-config hyprland)
    hyprctl plugin load $PWD/snowcaps.so

## Options

    hyprctl eval 'hl.config({ plugin = { snowcaps = { grow_minutes = 30, max_height = 32 } } })'

| option         | default      |                                   |
|----------------|--------------|-----------------------------------|
| grow_minutes   | 30           | minutes until a cap is full size  |
| max_height     | 32           | full cap height (px)              |
| col.snow       | 0xFFFFFFFF   | snow color (ARGB)                 |

Options reset to defaults on a Hyprland config reload; `winterctl apply` sets them again.
