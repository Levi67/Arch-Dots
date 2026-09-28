#!/usr/bin/env bash

export XDG_RUNTIME_DIR="/run/user/$(id -u)"
export WAYLAND_DISPLAY="${WAYLAND_DISPLAY:-wayland-0}"

# Start swww daemon if not running
if ! pgrep -x "swww-daemon" > /dev/null; then
    swww-daemon &
    sleep 1
fi

LAST_WALL=""
CACHE_DIR="$HOME/.cache/wallust"
HISTORY_DIR="$CACHE_DIR/history"
KITTY_CONF="$HOME/.config/kitty/colors.conf"

mkdir -p "$HISTORY_DIR"
echo "LOG: Wallust Poller (swww) Started with Caching."

while true; do
    # Get current wallpaper path using swww query
    CURRENT_WALL=$(swww query | grep -oP 'image: \K.*')

    if [[ "$CURRENT_WALL" != "$LAST_WALL" && -f "$CURRENT_WALL" ]]; then
        echo "LOG: Wallpaper change detected: $(basename "$CURRENT_WALL")"
        
        WALL_ID=$(md5sum "$CURRENT_WALL" | cut -d' ' -f1)
        
        if [ -f "$HISTORY_DIR/$WALL_ID" ]; then
            cp "$HISTORY_DIR/$WALL_ID" "$CACHE_DIR/sequences"
            wallust run -s "$CURRENT_WALL"
            SUCCESS=true
        else
            if timeout 20s wallust run "$CURRENT_WALL"; then
                cp "$CACHE_DIR/sequences" "$HISTORY_DIR/$WALL_ID"
                SUCCESS=true
            else
                SUCCESS=false
            fi
        fi

        if [ "$SUCCESS" = true ]; then
            if [ -f "$KITTY_CONF" ]; then
                kitten @ set-colors --all --configured "$KITTY_CONF"
                kitten @ set-colors --all "color9=#e0e0e0" "foreground=#ffffff"
                kitten @ set-background-opacity --all 0.60
            fi
        fi
        
        LAST_WALL="$CURRENT_WALL"
    fi
    
    sleep 1
done