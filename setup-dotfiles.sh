#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# Dotfiles Installation Script
#
# This script automates the setup of your dotfiles and user environment.
#
# Features:
#   - Stows user dotfiles using GNU Stow
#   - Creates required user directories
#   - Sets up and activates themes for Alacritty, i3, xsettingsd, Yazi, and SDDM
#   - Symlinks VS Code settings for related editors (Cursor, Windsurf)
#   - Modular: easily add new packages, themes, or services
#
# Prerequisites:
#   - bash
#   - GNU Stow
#   - git (for theme repositories)
#   - Optional: build-* scripts for i3, zellij, dunst, vscode, etc.
#
# Usage:
#   ./setup-dotfiles.sh [-t|--theme <theme_name>] [-h|--help]
#
# Options:
#   -t, --theme <theme_name>   Specify the initial theme to activate (default: gruvbox-dark)
#   -h, --help                 Show this help message
#
# Notes:
#   - Run this script from the root of your dotfiles repository.
#   - For SDDM theme installation, any existing theme directory will be removed before copying.
#   - Some steps are skipped if required commands are not found.
#
# -----------------------------------------------------------------------------

# Exit immediately if a command exits with a non-zero status.
set -e

THEME="gruvbox-dark" # Default theme
MODE="dark"          # Default mode

CONFIG_DIR="$HOME/.config"
LOCAL_DIR="$HOME/.local"

export PATH="$LOCAL_DIR/bin:$PATH"

# Common utility functions
# shellcheck disable=SC1091
source ./xdg_local/lib/utils.sh

# --- Usage Function ---
usage() {
    local script_name
    script_name=$(basename "$0")
    echo "Usage: $script_name [-t|--theme <theme_name>] [-h|--help]" >&2
    echo "  Installs dotfiles using stow and performs initial setup." >&2
    echo "  Options:" >&2
    echo "    -t, --theme <theme_name>  Specify the initial theme to activate (default: ${THEME})." >&2
    echo "    -h, --help                Show this help message." >&2
    exit 1
}

# --- Option Parsing ---
while [[ $# -gt 0 ]]; do
    case $1 in
    -t | --theme)
        if [[ -n $2 && $2 != -* ]]; then
            THEME="$2"
            shift # past argument
            shift # past value
        else
            echo "Error: Missing argument for $1 (theme name)" >&2
            usage
        fi
        ;;
    -h | --help)
        usage
        ;;
    --) # End of options
        shift
        break
        ;;
    -*)
        echo "Error: Unknown option '$1'" >&2
        usage
        ;;
    *)
        echo "Error: Unexpected argument '$1'" >&2
        usage
        ;;
    esac
done

# Create required directories user directories
user_dirs=(
    "${HOME}/.vscode"
    "${HOME}/.cursor"
    "${HOME}/.windsurf"
    "${CONFIG_DIR}/Code/User"
    "${CONFIG_DIR}/Cursor/User"
    "${CONFIG_DIR}/Windsurf/User"
    "${CONFIG_DIR}/easyeffects/output"
    "${LOCAL_DIR}/bin"
    "${LOCAL_DIR}/lib"
)
for dir in "${user_dirs[@]}"; do
    mkdir -p "$dir"
done

# --- Configuration ---
# Get the absolute path to the directory where this script resides (e.g., ~/.dotfiles)
DOTFILES_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)

# Define packages and their targets. Add more here if needed.
# Format: "package_directory_name:target_path"
USER_PACKAGES=(
    "home:$HOME"
    "xdg_config:${CONFIG_DIR}"
    "xdg_local:${LOCAL_DIR}"
)

# --- Pre-checks ---
log "Checking dependencies..."
check_command "stow"
log "Dependencies met."

# --- Stowing User Packages ---
log "Stowing user packages..."
cd "$DOTFILES_DIR" # Stow needs to be run from the parent of the package dirs

for item in "${USER_PACKAGES[@]}"; do
    IFS=":" read -r package target <<<"$item"
    package_path="$DOTFILES_DIR/$package"

    if [ -d "$package_path" ]; then
        log "Stowing '$package' to '$target'..."
        if stow -R -t "$target" "$package"; then
            log "Successfully stowed '$package'."
        else
            error "Failed to stow '$package'. Check stow output for details."
        fi
    else
        warning "Skipping package '$package': Directory does not exist at '$package_path'."
    fi
done

# --- Final Build/Activation Steps ---
log "Running final build/activation steps..."

log "Setting up default shell to zsh."
if ! command -v zsh &>/dev/null; then
    error "zsh command not found. Please install zsh first."
elif [ "$SHELL" != "$(command -v zsh)" ]; then
    chsh -s "$(command -v zsh)"
    log "Default shell set to zsh."
else
    log "Default shell already set to zsh."
fi

# Installing oh-my-zsh
if [ ! -d "$HOME/.oh-my-zsh" ]; then
    log "Installing oh-my-zsh..."
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended --keep-zshrc
    log "oh-my-zsh installed."
else
    log "oh-my-zsh already installed."
fi

# Installing zsh-autosuggestions
if [ ! -d "$HOME/.oh-my-zsh/custom/plugins/zsh-autosuggestions" ]; then
    log "Installing zsh-autosuggestions..."
    git clone https://github.com/zsh-users/zsh-autosuggestions "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-autosuggestions"
else
    log "zsh-autosuggestions already installed"
fi

# Installing zsh-syntax-highlighting
if [ ! -d "$HOME/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting" ]; then
    log "Installing zsh-syntax-highlighting..."
    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting"
else
    log "zsh-syntax-highlighting already installed"
fi

# Installing fast-syntax-highlighting
if [ ! -d "$HOME/.oh-my-zsh/custom/plugins/fast-syntax-highlighting" ]; then
    log "Installing fast-syntax-highlighting..."
    git clone https://github.com/zdharma-continuum/fast-syntax-highlighting.git "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/fast-syntax-highlighting"
else
    log "fast-syntax-highlighting already installed"
fi

# Installing zsh-history-substring-search
if [ ! -d "$HOME/.oh-my-zsh/custom/plugins/zsh-history-substring-search" ]; then
    log "Installing zsh-history-substring-search..."
    git clone https://github.com/zsh-users/zsh-history-substring-search.git "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-history-substring-search"
else
    log "zsh-history-substring-search already installed"
fi

# Setup Alacritty Themes
alacritty_themes_dir="${CONFIG_DIR}/alacritty/themes"
alacritty_themes_repo="https://github.com/alacritty/alacritty-theme.git" # Ensure .git suffix for clone
log "Checking Alacritty themes at '$alacritty_themes_dir'..."
if [ -d "$alacritty_themes_dir/.git" ]; then
    log "Alacritty themes directory exists and is a git repo, updating..."
    (cd "$alacritty_themes_dir" && git pull) || warning "Failed to update Alacritty themes repo."
elif [ -e "$alacritty_themes_dir" ]; then
    # Exists but is not a git directory (or is a file)
    warning "Path '$alacritty_themes_dir' exists but is not a git repository. Skipping theme clone/update."
else
    log "Cloning Alacritty themes repository..."
    if git clone --depth 1 "$alacritty_themes_repo" "$alacritty_themes_dir"; then
        log "Successfully cloned Alacritty themes."
    else
        warning "Failed to clone Alacritty themes repository."
    fi
fi

# Setup bat
if command -v bat &>/dev/null; then
    log "Setting up bat..."
    bat cache --build
fi

# Setup the active theme
if [ -f "${CONFIG_DIR}/themes/${THEME}/theme.sh" ]; then
    ln -sf "${CONFIG_DIR}/themes/${THEME}/theme.sh" "${CONFIG_DIR}/themes/active-theme.sh"
    source "${CONFIG_DIR}/themes/active-theme.sh" # probably not needed, the individual scripts source the theme file
else
    error "Active theme file not found: ${CONFIG_DIR}/themes/${THEME}/theme.sh. Cannot create active-theme symlink."
fi

if command -v gsettings &>/dev/null; then
    gsettings set org.gnome.desktop.interface color-scheme "prefer-${MODE}"
else
    warning "gsettings command not found. Skipping setting color-scheme preference for GNOME/GTK."
fi
log "Active theme set to ${THEME}."

# Zellij Config Build
if command -v build-zellij-config &>/dev/null; then
    log "Running build-zellij-config..."
    if build-zellij-config -q -t "$THEME"; then
        log "Successfully ran build-zellij-config."
    else
        warning "build-zellij-config command failed."
    fi
else
    warning "'build-zellij-config' command not found. Skipping."
fi

# i3 Config Build
if command -v build-i3-config &>/dev/null; then
    log "Running build-i3-config..."
    if build-i3-config -q -t "$THEME"; then
        log "Successfully ran build-i3-config."
    else
        warning "build-i3-config command failed."
    fi
else
    warning "'build-i3-config' command not found. Skipping."
fi

# xsettingsd Config (GTK Apps) - Default to dark theme
log "Setting up xsettingsd..."
if ! command -v xsettingsd &>/dev/null; then
    warning "'xsettingsd' command not found. Install it to be able to auto-switch themes in GTK apps."
fi
ln -sf "${CONFIG_DIR}/xsettingsd/themes/${THEME}.conf" "${CONFIG_DIR}/xsettingsd/xsettingsd.conf"

# Yazi Setup
log "Setting up yazi..."
if ! command -v yazi &>/dev/null; then
    warning "'yazi' command not found. Please install yazi first and run manually: ya pack -u"
else
    log "Updating Yazi packages..."
    if ya pack -u; then
        log "Successfully updated Yazi packages."
    else
        warning "Failed to update Yazi packages. You might need to run 'ya pack -u' manually."
    fi
fi
# Zellij and Yazi light theme incompatibility forces this
# TODO: Fix this when zellij supports light themes of yazi
ln -sf "${CONFIG_DIR}/yazi/themes/theme-${THEME}.toml" "${CONFIG_DIR}/yazi/theme.toml"

# VS Code and related editor settings (Cursor, Windsurf, etc)
log "Setting up VS Code and related editor settings..."
# Create symlinks (overwrite if they exist and are not already correct)
ln -sf "${CONFIG_DIR}/Code/User/settings.json" "${CONFIG_DIR}/Cursor/User/settings.json"
ln -sf "${CONFIG_DIR}/Code/User/settings.json" "${CONFIG_DIR}/Windsurf/User/settings.json"
ln -sf "${HOME}/.vscode/argv.json" "${HOME}/.cursor/argv.json"
ln -sf "${HOME}/.vscode/argv.json" "${HOME}/.windsurf/argv.json"
# Build the VS Code settings
if command -v build-vscode-settings &>/dev/null; then
    log "Running build-vscode-settings..."
    if build-vscode-settings -q -t "$THEME"; then
        log "Successfully ran build-vscode-settings."
    else
        warning "build-vscode-settings command failed."
    fi
else
    warning "'build-vscode-settings' command not found. Skipping."
fi

# Dunst Config Build
log "Building dunst config..."
if command -v build-dunst-config &>/dev/null; then
    log "Running build-dunst-config..."
    if build-dunst-config; then
        log "Successfully ran build-dunst-config."
    else
        warning "build-dunst-config command failed."
    fi
else
    warning "'build-dunst-config' command not found. Skipping."
fi

# Rofi Config Build
log "Building rofi config..."
if command -v build-rofi-config &>/dev/null; then
    log "Running build-rofi-config..."
    if build-rofi-config; then
        log "Successfully ran build-rofi-config."
    else
        warning "build-rofi-config command failed."
    fi
else
    warning "'build-rofi-config' command not found. Skipping."
fi

log "**** Dotfiles installation script finished! ****"
