#!/usr/bin/env bash

# Exit immediately if a command exits with a non-zero status.
set -e

THEME="gruvbox-dark" # Default theme

# --- Helper Functions ---
log() {
    echo "[INFO] $1"
}

warning() {
    # Yellow color: \033[1;33m, Reset: \033[0m
    echo -e "\033[1;33m[WARN] $1\033[0m"
}

error() {
    # Red color: \033[1;31m, Reset: \033[0m
    echo -e "\033[1;31m[ERROR] $1\033[0m" >&2
    exit 1
}

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

# --- Configuration ---
# Get the absolute path to the directory where this script resides (e.g., ~/.dotfiles)
DOTFILES_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)

# Define packages and their targets. Add more here if needed.
# Format: "package_directory_name:target_path"
# Note: 'etc' target is handled separately due to sudo requirement.
USER_PACKAGES=(
    "home:$HOME"
    "xdg_config:$HOME/.config"
    "xdg_local:$HOME/.local"
)
SYSTEM_PACKAGE="etc"
SYSTEM_TARGET="/etc"

# Define systemd services within the system package that need enabling.
SYSTEMD_SERVICES=(
    "lock-screen-before-sleep@ioangel.service"
    # Add other service filenames here if you add more under etc/systemd/system/
)

# --- Pre-checks ---
log "Checking dependencies..."
if ! command -v stow &>/dev/null; then
    error "'stow' command not found. Please install stow first."
fi
if ! command -v sudo &>/dev/null && [ "$SYSTEM_PACKAGE" != "" ]; then
    error "'sudo' command not found, but it's required for the system package '$SYSTEM_PACKAGE'."
fi
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

# --- Post-Stow Steps (User) ---
log "Performing post-stow steps for user packages..."

# 1. Alacritty Themes
alacritty_themes_dir="$HOME/.config/alacritty/themes"
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

# --- Stowing System Package ---
log "Stowing system package (requires sudo)..."
system_package_path="$DOTFILES_DIR/$SYSTEM_PACKAGE"

if [ -d "$system_package_path" ]; then
    log "Stowing '$SYSTEM_PACKAGE' to '$SYSTEM_TARGET' using sudo..."
    if sudo stow -R -t "$SYSTEM_TARGET" "$SYSTEM_PACKAGE"; then
        log "Successfully stowed '$SYSTEM_PACKAGE'."
    else
        error "Failed to stow '$SYSTEM_PACKAGE' with sudo. Check permissions and stow output."
    fi

    # --- Post-Activation for System Package (systemd) ---
    if [ ${#SYSTEMD_SERVICES[@]} -gt 0 ]; then
        log "Performing systemd post-activation steps..."
        if sudo systemctl daemon-reload; then
            log "Reloaded systemd daemon."
        else
            error "Failed to reload systemd daemon."
        fi

        for service in "${SYSTEMD_SERVICES[@]}"; do
            service_file_path="$system_package_path/systemd/system/$service" # Check existence in dotfiles
            if [ -f "$service_file_path" ]; then
                log "Enabling systemd service '$service'..."
                # Use --now to enable and start, or just enable if you prefer manual start
                if sudo systemctl enable "$service"; then
                    log "Enabled '$service'."
                else
                    # Don't exit script, maybe just needs manual intervention
                    warning "Failed to enable '$service'. It might already be enabled or have issues."
                fi
                # Optional: Start the service
                # log "Starting systemd service '$service'..."
                # if sudo systemctl start "$service"; then
                #     log "Started '$service'."
                # else
                #     warning "Failed to start '$service'. It might already be running or have issues."
                # fi
            else
                warning "Skipping systemd service '$service': File not found at '$service_file_path'."
            fi
        done
    else
        log "No systemd services defined for post-activation."
    fi
else
    warning "Skipping system package '$SYSTEM_PACKAGE': Directory does not exist at '$system_package_path'."
fi

# --- Final Build/Activation Steps (User) ---
log "Running final build/activation steps..."

# 2. Zellij Config Build
if command -v build-zellij-config &>/dev/null; then
    log "Running build-zellij-config..."
    if build-zellij-config -t "$THEME"; then
        log "Successfully ran build-zellij-config."
    else
        warning "build-zellij-config command failed."
    fi
else
    warning "'build-zellij-config' command not found. Skipping."
fi

# 3. i3 Config Build
if command -v build-i3-config &>/dev/null; then
    log "Running build-i3-config..."
    if build-i3-config -t "$THEME"; then
        log "Successfully ran build-i3-config."
    else
        warning "build-i3-config command failed."
    fi
else
    warning "'build-i3-config' command not found. Skipping."
fi

# 4. xsettingsd Config (GTK Apps) - Default to dark theme
log "Setting up xsettingsd..."
if ! command -v xsettingsd &>/dev/null; then
    warning "'xsettingsd' command not found. Install it to be able to auto-switch themes in GTK apps."
fi
ln -sf ~/.config/xsettingsd/themes/${THEME}.conf ~/.config/xsettingsd/xsettingsd.conf

# 5. Polybar Config
log "Setting up polybar..."
if ! command -v polybar &>/dev/null; then
    warning "'polybar' command not found."
fi
ln -sf ~/.config/polybar/modules/themes/${THEME}.ini ~/.config/polybar/modules/colors.ini

# 6. Yazi Setup
log "Setting up yazi..."
if ! command -v yazi &>/dev/null; then
    warning "'yazi' command not found."
    warning "Please install yazi first and run manually: ya pack -u"
else
    ya pack -u
    log "Successfully setup yazi."
fi
# Zellij and Yazi light theme incompatibility forces this
# TODO: Fix this when zellij supports light themes of yazi
ln -sf ~/.config/yazi/themes/theme-${THEME}.toml ~/.config/yazi/theme.toml

# 7. VS Code and related editor settings (Cursor, Windsurf, etc)
log "Setting up VS Code and related editor settings..."
# Ensure parent directories exist
mkdir -p ~/.config/Cursor/User
mkdir -p ~/.config/Windsurf/User
# Create symlinks (overwrite if they exist and are not already correct)
ln -sf ~/.config/Code/User/settings.json ~/.config/Cursor/User/settings.json
ln -sf ~/.config/Code/User/settings.json ~/.config/Windsurf/User/settings.json
# Build the VS Code settings
if command -v build-vscode-settings &>/dev/null; then
    log "Running build-vscode-settings..."
    if build-vscode-settings -t "$THEME"; then
        log "Successfully ran build-vscode-settings."
    else
        warning "build-vscode-settings command failed."
    fi
else
    warning "'build-vscode-settings' command not found. Skipping."
fi

log "Dotfiles installation script finished!"

exit 0
