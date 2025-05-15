#!/usr/bin/env bash
# shellcheck disable=SC1090

# Initialize new launch
echo "-------------------" | tee -a /tmp/polybar_main.log

# Terminate already running bar instances
# If all your bars have ipc enabled, you can use
polybar-msg cmd quit
# Otherwise you can use the nuclear option:
# killall -q polybar

# Wait until the processes have been shut down
while pgrep -u $UID -x polybar >/dev/null; do sleep 1; done

# Set the default profile
export POLYBAR_PROFILE="default" # main dekstop with hostname: erebus

if command -v systemd-detect-virt &>/dev/null && systemd-detect-virt -q; then # detect if running in a VM
    export POLYBAR_PROFILE="vm"
elif [ "$(hostname)" = "hades" ]; then # ThinkPad Laptop
    export POLYBAR_PROFILE="laptop"
fi

# Define paths for Polybar profile layouts
layouts_dir="$HOME/.config/polybar/profile_layouts"
active_layout_symlink="${layouts_dir}/active_layout.ini"
target_profile_file="${layouts_dir}/${POLYBAR_PROFILE}.ini"

# Ensure the target profile file exists
if [ ! -f "$target_profile_file" ]; then
    echo "[ERROR] Polybar profile layout file not found: $target_profile_file. Falling back to default." | tee -a /tmp/polybar_main.log
    # Attempt to use default as a fallback if the specific profile is missing
    if [ -f "${layouts_dir}/default.ini" ]; then
        target_profile_file="${layouts_dir}/default.ini"
    else
        echo "[ERROR] Default Polybar profile layout file also not found: ${layouts_dir}/default.ini. Cannot launch Polybar." | tee -a /tmp/polybar_main.log
        exit 1 # Exit if no usable profile can be found
    fi
fi

# Create/update the symlink to the active profile layout
ln -sf "$target_profile_file" "$active_layout_symlink"
echo "Symlink created: $active_layout_symlink -> $target_profile_file" | tee -a /tmp/polybar_main.log

# source the active theme if it exists
ACTIVE_THEME_FILE="$HOME/.config/themes/active-theme.sh"
if [ -f "$ACTIVE_THEME_FILE" ]; then
    source "$ACTIVE_THEME_FILE"
else
    echo "[WARN] Active theme file not found: $ACTIVE_THEME_FILE. Polybar might use default colors." | tee -a /tmp/polybar_main.log
fi

# --- Launch Polybar ---
echo "Polybar launching with PROFILE=${POLYBAR_PROFILE}" | tee -a /tmp/polybar_main.log
polybar main 2>&1 | tee -a /tmp/polybar_main.log &
disown

echo "Polybar launched..."
