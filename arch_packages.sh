#!/bin/sh
# WORK IN PROGRESS

# --- Core Window Manager & Bar ---
sudo pacman -S i3-wm i3blocks i3lock xss-lock

# --- Terminal Emulators ---
sudo pacman -S wezterm
# (Optional: alacritty xfce4-terminal)

# --- Compositor & Status Bar ---
sudo pacman -S picom polybar

# --- Application Launchers & Menus ---
sudo pacman -S rofi

# --- GTK Themes/ Icons ---
yay -S yaru-gtk-theme yaru-icon-theme

# --- Fonts ---
sudo pacman -S ttf-cascadia-mono-nerd ttf-cascadia-code-nerd ttf-font-awesome ttf-jetbrains-mono-nerd

# --- File Managers ---
sudo pacman -S thunar yazi

# --- Browsers, Editors, IDEs ---
sudo pacman -S obsidian nvim firefox
yay -S google-chrome neovim-remote visual-studio-code-bin cursor-extracted brave-bin

# --- Utilities ---
sudo pacman -S \
    xbacklight libnotify alsa-utils playerctl pavucontrol xorg-xkill xsettingsd polkit-gnome \
    nitrogen xorg-xset numlockx conky redshift-gtk network-manager-applet solaar 1password \
    synology-drive easyeffects imagemagick scrot flameshot jq wget python python-pipx \
    dunst bat maim xdotool xorg-xrandr docker pciutils usbutils the_silver_searcher ripgrep \
    gsettings-desktop-schemas gettext sops fastfetch

yay -S caffeine-ng

# --- Power Management ---
sudo pacman -S power-profiles-daemon

# --- Network & Miscellaneous CLI ---
sudo pacman -S iproute2 inetutils wireless_tools

# --- Zsh & Shell Environment ---
sudo pacman -S zsh git fzf starship zoxide findutils grep sed coreutils
yay -S oh-my-zsh zsh-syntax-highlighting zsh-autosuggestions mise zellij lazydocker lazygit fd 1password-cli kubectx kubens

# --- AUR/Optional/Recommended ---
yay -S rofi-greenclip xkblayout-state-git gnome-pomodoro-git i3-gnome-pomodoro
# (Optional: dex xscreensaver lxpolkit bottles pamac-aur blueberry)

# --- Ruby (if needed for scripts) ---
# For Ruby: gem install bundler
