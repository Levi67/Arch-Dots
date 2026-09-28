#!/usr/bin/env bash

# Force correct Wayland display and runtime directory
export XDG_RUNTIME_DIR="/run/user/$(id -u)"
export WAYLAND_DISPLAY="${WAYLAND_DISPLAY:-wayland-0}"

# --- CONFIGURATION ---
LAST_WALL=""
CACHE_DIR="$HOME/.cache/wallust"
HISTORY_DIR="$CACHE_DIR/history"
KITTY_CONF="$HOME/.config/kitty/colors.conf"

# Ensure history directory exists
mkdir -p "$HISTORY_DIR"

echo "LOG: Wallust Poller (awww) Started with Caching."

while true; do
    # 1. Get current wallpaper path (grab only the first monitor's image)
    CURRENT_WALL=$(awww query 2>/dev/null | grep -oP 'image: \K.*' | head -n 1 | xargs)

    # 2. Check if wallpaper actually changed, exists, and isn't empty
    if [[ -n "$CURRENT_WALL" && "$CURRENT_WALL" != "$LAST_WALL" && -f "$CURRENT_WALL" ]]; then
        echo "LOG: Wallpaper change detected: $(basename "$CURRENT_WALL")"
        
        # 3. Create a unique fingerprint for this image
        WALL_ID=$(md5sum "$CURRENT_WALL" | cut -d' ' -f1)
        
        if [ -f "$HISTORY_DIR/$WALL_ID" ]; then
            echo "LOG: Cache Hit ($WALL_ID). Fast-applying templates..."
            cp "$HISTORY_DIR/$WALL_ID" "$CACHE_DIR/sequences"
            wallust run -s "$CURRENT_WALL"
            SUCCESS=true
        else
            echo "LOG: Cache Miss. Running full analysis..."
            if timeout 20s wallust run "$CURRENT_WALL"; then
                cp "$CACHE_DIR/sequences" "$HISTORY_DIR/$WALL_ID"
                SUCCESS=true
            else
                echo "ERROR: Wallust timed out or failed!"
                SUCCESS=false
            fi
        fi

        # 4. Apply changes to running applications
        if [ "$SUCCESS" = true ]; then
            echo "LOG: Applying colors to terminals..."
            if [ -f "$KITTY_CONF" ]; then
                kitten @ set-colors --all --configured "$KITTY_CONF"
                kitten @ set-colors --all "color9=#e0e0e0" "foreground=#ffffff"
                kitten @ set-background-opacity --all 0.60
            fi
        fi
        
        LAST_WALL="$CURRENT_WALL"
    fi
    
    sleep 2
done