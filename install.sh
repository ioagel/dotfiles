#!/usr/bin/env bash

# Exit immediately if a command exits with a non-zero status.
set -e

# --- Configuration ---
# Get the absolute path to the directory where this script resides (e.g., ~/.dotfiles)
DOTFILES_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

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

# --- Helper Functions ---
log() {
    echo "[INFO] $1"
}

warning() {
    echo "[WARN] $1"
}

error() {
    echo "[ERROR] $1" >&2
    exit 1
}

# --- Pre-checks ---
log "Checking dependencies..."
if ! command -v stow &> /dev/null; then
    error "'stow' command not found. Please install stow first."
fi
if ! command -v sudo &> /dev/null && [ "$SYSTEM_PACKAGE" != "" ]; then
    error "'sudo' command not found, but it's required for the system package '$SYSTEM_PACKAGE'."
fi
log "Dependencies met."

# --- Stowing User Packages ---
log "Stowing user packages..."
cd "$DOTFILES_DIR" # Stow needs to be run from the parent of the package dirs

for item in "${USER_PACKAGES[@]}"; do
    IFS=":" read -r package target <<< "$item"
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
    if git clone "$alacritty_themes_repo" "$alacritty_themes_dir"; then
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
if command -v build-zellij-config &> /dev/null; then
    log "Running build-zellij-config..."
    if build-zellij-config -t gruvbox-dark; then
        log "Successfully ran build-zellij-config."
    else
        warning "build-zellij-config command failed."
    fi
else
    warning "'build-zellij-config' command not found. Skipping."
fi

# 3. i3 Config Build
if command -v build-i3-config &> /dev/null; then
    log "Running build-i3-config..."
    if build-i3-config -t gruvbox; then
        log "Successfully ran build-i3-config."
    else
        warning "build-i3-config command failed."
    fi
else
    warning "'build-i3-config' command not found. Skipping."
fi

log "Dotfiles installation script finished!"

exit 0
