#!/usr/bin/env fish

set REPO_DIR (dirname (status filename))
cd $REPO_DIR

# Ensure ~/.config exists
mkdir -p ~/.config

# Get all directories, excluding hidden ones or specific files
for pkg in */
    set pkg_name (string trim -r -c '/' $pkg)
    echo "Stowing $pkg_name..."
    stow -t ~ -R $pkg_name
end

echo "All dotfiles stowed successfully!"
