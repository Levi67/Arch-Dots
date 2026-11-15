#!/bin/sh
# Toggle the vibrance shader and remember the choice across config reloads.
STATE="${XDG_STATE_HOME:-$HOME/.local/state}/hypr/vibrance"
SHADER="$HOME/.config/hypr/shaders/vibrance.glsl"
mkdir -p "$(dirname "$STATE")"
if [ "$(cat "$STATE" 2>/dev/null)" = "off" ]; then
    echo on >"$STATE"; hyprshade on "$SHADER"
else
    echo off >"$STATE"; hyprshade off
fi
