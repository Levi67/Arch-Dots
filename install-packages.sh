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
    jq
    # desktop settings app (Quickshell): bluetooth, night light, monitor brightness over DDC/CI
    bluez
    bluez-utils
    hyprsunset
    ddcutil
    power-profiles-daemon
    # case RGB (rgb/.config/rgb/rgbctl): RAM + motherboard
    openrgb
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
    # case RGB: Python client for rgbctl; OpenLinkHub drives the Corsair hub (fans + its LEDs)
    python-openrgb
    openlinkhub-bin
)

echo "=== Installing AUR Packages ==="
yay -S --needed --noconfirm "${AUR_PKGS[@]}"

# 5. Enable Flathub Integration
echo "=== Configuring Flatpak / Flathub ==="
sudo flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo

# 6. Enable Ly Display Manager Service
echo "=== Enabling Ly Login Screen ==="
sudo systemctl enable ly.service

# 6b. Desktop settings backends
echo "=== Enabling Bluetooth, power profiles and DDC/CI (monitor brightness) ==="
sudo systemctl enable --now bluetooth.service
sudo systemctl enable --now power-profiles-daemon.service
# ddcutil talks to monitors over /dev/i2c-*; load the module now and on every boot
echo i2c-dev | sudo tee /etc/modules-load.d/i2c-dev.conf >/dev/null
sudo modprobe i2c-dev || true

# 6c. Case RGB: dark at boot/sleep, OpenRGB kept off the Corsair hub (see rgb/.config/rgb/rgbctl).
# OpenLinkHub itself needs per-machine setup in its web UI / config (OpenRGB bridge, LED ports).
echo "=== Case RGB ==="
# the package's udev rule names a user it creates afterwards; udevd only resolves it after a restart
sudo systemctl restart systemd-udevd
sudo udevadm trigger --action=add --subsystem-match=hidraw
sudo "$(dirname "$(readlink -f "$0")")/rgb/.config/rgb/system/install-system"

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
