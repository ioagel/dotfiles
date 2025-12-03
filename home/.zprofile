# ~/.zprofile
# Main environment setup for login shells (TTY, SSH, SDDM X11/Wayland for Zsh)

# set locale
export LANG="en_US.UTF-8"        # Primary language for UI, messages
export LC_MESSAGES="en_US.UTF-8" # For English messages, or el_GR.UTF-8 for Greek

export LC_CTYPE="el_GR.UTF-8"   # CRITICAL: For Greek character handling and display
export LC_COLLATE="el_GR.UTF-8" # Or en_US.UTF-8 if you prefer English sorting
# export LC_NAME="el_GR.UTF-8" # Uncomment and set if needed for name formatting
# export LC_IDENTIFICATION="el_GR.UTF-8" # Uncomment and set if needed
export LC_NUMERIC="el_GR.UTF-8"
export LC_TIME="el_GR.UTF-8"
export LC_MONETARY="el_GR.UTF-8"
export LC_PAPER="el_GR.UTF-8"
export LC_ADDRESS="el_GR.UTF-8"
export LC_TELEPHONE="el_GR.UTF-8"
export LC_MEASUREMENT="el_GR.UTF-8"

# Set editor
if type nvim >/dev/null 2>&1; then
    export EDITOR=nvim
else
    export EDITOR=vim
fi
export VISUAL=$EDITOR
export SUDO_EDITOR=$EDITOR

# Set terminal
export TERMINAL=wezterm
# Set browser
# export BROWSER=brave
export BROWSER=google-chrome-stable

# GUI Theming & Toolkits
export QT_QPA_PLATFORMTHEME=qt5ct
# export QT_QPA_PLATFORMTHEME=qt6ct
export GTK2_RC_FILES="$HOME/.gtkrc-2.0"

# Variables for i3blocks (if they need to be available broadly,
# otherwise they could remain in your i3 config or an i3-specific startup script)
# [CPU-temperature] block
export T_WARN=75
export T_CRIT=95
# uses sensors output for chip
export SENSOR_CHIP="k10temp-pci-00c3"

# Load common path configuration
# shellcheck source=/dev/null
[ -f ~/.path_common.sh ] && . ~/.path_common.sh
