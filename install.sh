#!/usr/bin/env bash

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
DOTFILES_DIR="$SCRIPT_DIR"
BACKUP_DIR="$HOME/.config-backup-$(date +%Y%m%d-%H%M%S)"

echo "==========================================="
echo "    AstraDothFiles Auto-Install Script"
echo "==========================================="
echo ""

IS_ROOT=$(id -u)

if [ "$IS_ROOT" -ne 0 ]; then
    echo "[!] Run as root (sudo ./install.sh) for system installation"
    exit 1
fi

echo "[1/7] Detecting GPU..."
GPU=$(lspci | grep -E "VGA|Graphics" | grep -i "nvidia" || echo "none")
if [[ "$GPU" == *"nvidia"* ]]; then
    echo "Found NVIDIA GPU"
    NVIDIA=1
else
    NVIDIA=0
fi

echo ""
echo "[2/7] Checking installed packages..."
INSTALLED_PKGS=$(pacman -Qq | wc -l)
echo "Currently installed: $INSTALLED_PKGS packages"

if [ -f "$DOTFILES_DIR/packages.txt" ]; then
    echo "Found packages.txt with $(wc -l < $DOTFILES_DIR/packages.txt) packages"
fi

echo ""
echo "[3/7] Installing NVIDIA drivers..."
if [ "$NVIDIA" -eq 1 ]; then
    pacman -Sy --noconfirm nvidia nvidia-utils nvidia-settings lib32-nvidia-utils
    nvidia-xconfig >/dev/null 2>&1 || true
    echo "NVIDIA drivers installed!"
else
    echo "No NVIDIA GPU detected, skipping..."
fi

echo ""
echo "[4/7] Installing core Hyprland packages..."
HYPRLAND_PKGS=(
    hyprland
    waybar
    rofi
    kitty
    wofi
    wlogout
    fastfetch
    hyprlock
    dunst
    networkmanager
    blueman
    thunar
    firefox
    neofetch
    fastfetch
    exa
    bat
    fzf
    ripgrep
    unzip
    rofi-emoji
    pamixer
    brightnessctl
    playerctl
    xdg-user-dirs
    polkit-gnome
    gvfs
    thunar-archive-plugin
    thunar-volman
    nautilus
)

for pkg in "${HYPRLAND_PKGS[@]}"; do
    if pacman -Qq "$pkg" >/dev/null 2>&1; then
        echo "  [OK] $pkg already installed"
    else
        echo "  [+] Installing $pkg..."
        pacman -Sy --noconfirm "$pkg" 2>/dev/null || echo "  [!] Failed to install $pkg"
    fi
done

echo ""
echo "[5/7] Creating backup of existing config..."
mkdir -p "$BACKUP_DIR"
cp -r "$HOME/.config/hypr" "$HOME/.config/waybar" "$HOME/.config/rofi" "$HOME/.config/kitty" "$HOME/.config/wofi" "$HOME/.config/wlogout" "$HOME/.config/fastfetch" "$HOME/.config/hyprlock" "$HOME/.config/dunst" "$BACKUP_DIR/" 2>/dev/null || true
echo "Backup created at: $BACKUP_DIR"

echo ""
echo "[6/7] Linking config files..."
chown -R "$SUDO_USER:$SUDO_USER" "$DOTFILES_DIR" 2>/dev/null || true

su - "$SUDO_USER" -c "
    mkdir -p \$HOME/.config
    rm -rf \$HOME/.config/hypr \$HOME/.config/waybar \$HOME/.config/rofi \$HOME/.config/kitty \$HOME/.config/wofi \$HOME/.config/wlogout \$HOME/.config/fastfetch \$HOME/.config/hyprlock 2>/dev/null || true
    
    ln -sf '$DOTFILES_DIR/.config/hypr' \$HOME/.config/hypr
    ln -sf '$DOTFILES_DIR/.config/waybar' \$HOME/.config/waybar
    ln -sf '$DOTFILES_DIR/.config/rofi' \$HOME/.config/rofi
    ln -sf '$DOTFILES_DIR/.config/kitty' \$HOME/.config/kitty
    ln -sf '$DOTFILES_DIR/.config/wofi' \$HOME/.config/wofi
    ln -sf '$DOTFILES_DIR/.config/wlogout' \$HOME/.config/wlogout
    ln -sf '$DOTFILES_DIR/.config/fastfetch' \$HOME/.config/fastfetch
    ln -sf '$DOTFILES_DIR/.config/hyprlock' \$HOME/.config/hyprlock
    [ -d '$DOTFILES_DIR/.config/gtk-3.0' ] && ln -sf '$DOTFILES_DIR/.config/gtk-3.0' \$HOME/.config/gtk-3.0
    [ -d '$DOTFILES_DIR/.config/gtk-4.0' ] && ln -sf '$DOTFILES_DIR/.config/gtk-4.0' \$HOME/.config/gtk-4.0
    [ -d '$DOTFILES_DIR/.config/nwg-look' ] && ln -sf '$DOTFILES_DIR/.config/nwg-look' \$HOME/.config/nwg-look
    
    mkdir -p \$HOME/Pictures/wallpapers
    cp -n '$DOTFILES_DIR/wallpapers/'* \$HOME/Pictures/wallpapers/ 2>/dev/null || true
    
    [ -f '$DOTFILES_DIR/.bashrc' ] && ln -sf '$DOTFILES_DIR/.bashrc' \$HOME/.bashrc
    [ -f '$DOTFILES_DIR/.zshrc' ] && ln -sf '$DOTFILES_DIR/.zshrc' \$HOME/.zshrc
"
echo "Configs linked!"

echo ""
echo "[7/7] Enabling services..."
systemctl enable NetworkManager 2>/dev/null || true
systemctl enable bluetooth 2>/dev/null || true

echo ""
echo "==========================================="
echo "    Installation complete!"
echo "==========================================="
echo ""
echo "Configs: ~/.config/"
echo "Wallpapers: ~/Pictures/wallpapers/"
echo "Backup: $BACKUP_DIR"
echo ""
echo "For GPU drivers to take effect, REBOOT system"
echo "To apply Hyprland: killall Hyprland or logout/login"