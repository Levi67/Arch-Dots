#!/usr/bin/env bash

set -e

echo "=== Updating System ==="
sudo pacman -Syu --noconfirm

# 1. Install Yay (AUR Helper) if not already installed
if ! command -v yay &> /dev/null; then
    echo "=== Installing Yay (AUR Helper) ==="
    sudo pacman -S --needed --noconfirm base-devel git
    git clone https://aur.archlinux.org/yay.git /tmp/yay
    (cd /tmp/yay && makepkg -si --noconfirm)
    rm -rf /tmp/yay
fi

# 2. Enable Multilib Repository for Steam
echo "=== Enabling Multilib Repository ==="
if ! grep -q "^\[multilib\]" /etc/pacman.conf; then
    echo -e "\n[multilib]\nInclude = /etc/pacman.d/mirrorlist" | sudo tee -a /etc/pacman.conf
    sudo pacman -Sy
fi

# 3. Official Arch Packages
PACMAN_PKGS=(
    hyprland
    xdg-desktop-portal
    xdg-desktop-portal-hyprland
    xdg-desktop-portal-gtk
    swww
    easyeffects
    steam
    flatpak
    kitty
    ly
    spotify
    curl
    tar
)

echo "=== Installing Official Packages ==="
sudo pacman -S --needed --noconfirm "${PACMAN_PKGS[@]}"

# 4. AUR Packages
AUR_PKGS=(
    waypaper
    quickshell-git
    hyprpolkitagent
    vscodium-bin
    vesktop-bin
    zen-browser-bin
    spicetify-cli
)

echo "=== Installing AUR Packages ==="
yay -S --needed --noconfirm "${AUR_PKGS[@]}"

# 5. Enable Flathub Integration
echo "=== Configuring Flatpak / Flathub ==="
sudo flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo

# 6. Enable Ly Display Manager Service
echo "=== Enabling Ly Login Screen ==="
sudo systemctl enable ly.service

# 7. Setup Spicetify Permissions & Initial Inject
echo "=== Setting Up Spicetify ==="
# Grant write permissions to Spotify client directory for Spicetify
sudo chmod a+wr /opt/spotify
sudo chmod a+wr /opt/spotify/Apps -R

# Run initial Spicetify configuration
if command -v spicetify &> /dev/null; then
    spicetify config current_theme marketplace || true
    spicetify apply || true
fi

echo "=== Installation Complete! ==="
echo "You can now reboot your system or start 'ly' with: sudo systemctl start ly"
