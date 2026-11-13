#!/usr/bin/env fish

set REPO_DIR (dirname (status filename))
cd $REPO_DIR

# Ensure ~/.config exists
mkdir -p ~/.config

# Get all directories, excluding hidden ones or specific files
for pkg in */
    set pkg_name (string trim -r -c '/' $pkg)
    # not a dotfiles package: source code (e.g. the snowcaps Hyprland plugin, built by winterctl)
    if test "$pkg_name" = plugins
        continue
    end
    echo "Stowing $pkg_name..."
    stow -t ~ -R $pkg_name
end

echo "All dotfiles stowed successfully!"
