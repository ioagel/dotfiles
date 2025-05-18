#!/usr/bin/env bash
# shellcheck disable=SC1090

# Source the utils library, for is_laptop function
source ~/.local/lib/utils.sh

# Initialize new launch
echo "-------------------" | tee -a /tmp/polybar_main.log

# Terminate already running bar instances
# If all your bars have ipc enabled, you can use
polybar-msg cmd quit
# Otherwise you can use the nuclear option:
# killall -q polybar

# Wait until the processes have been shut down
while pgrep -u $UID -x polybar >/dev/null; do sleep 1; done

# source the active theme if it exists
ACTIVE_THEME_FILE="$HOME/.config/themes/active-theme.sh"
if [ -f "$ACTIVE_THEME_FILE" ]; then
    source "$ACTIVE_THEME_FILE"
else
    echo "[WARN] Active theme file not found: $ACTIVE_THEME_FILE. Polybar might use default colors." | tee -a /tmp/polybar_main.log
fi

# --- Launch Polybar ---
# Decide how many monitors we have and display the appropriate bars
active_monitors=$(xrandr --listactivemonitors | grep -oP '^\s*(\d+)' | wc -l)

if [ "$active_monitors" -eq 3 ]; then
    echo "-------------------" | tee -a /tmp/polybar_3monitors.log
    echo "Running on 3 monitors" | tee -a /tmp/polybar_3monitors.log
    polybar vm-0 2>&1 | tee -a /tmp/polybar_3monitors.log &
    disown
    polybar vm-1 2>&1 | tee -a /tmp/polybar_3monitors.log &
    disown
    polybar vm-2 2>&1 | tee -a /tmp/polybar_3monitors.log &
    disown
elif [ "$active_monitors" -eq 2 ]; then
    echo "-------------------" | tee -a /tmp/polybar_2monitors.log
    echo "Running on 2 monitors" | tee -a /tmp/polybar_2monitors.log
    polybar vm-0 2>&1 | tee -a /tmp/polybar_2monitors.log &
    disown
    polybar vm-1 2>&1 | tee -a /tmp/polybar_2monitors.log &
    disown
else
    # Set the default profile
    export POLYBAR_PROFILE="default" # main desktop

    if command -v systemd-detect-virt &>/dev/null && systemd-detect-virt -q; then # detect if running in a VM
        export POLYBAR_PROFILE="vm"
    elif is_laptop; then # detect if running in a laptop
        export POLYBAR_PROFILE="laptop"
    fi

    # Define paths for Polybar profile layouts
    layouts_dir="$HOME/.config/polybar/profile_layouts"
    active_layout_symlink="${layouts_dir}/active_layout.ini"
    target_profile_file="${layouts_dir}/${POLYBAR_PROFILE}.ini"

    # Create/update the symlink to the active profile layout
    ln -sf "$target_profile_file" "$active_layout_symlink"
    echo "Symlink created: $active_layout_symlink -> $target_profile_file" | tee -a /tmp/polybar_main.log

    echo "Polybar launching with PROFILE=${POLYBAR_PROFILE}" | tee -a /tmp/polybar_main.log
    polybar main 2>&1 | tee -a /tmp/polybar_main.log &
    disown
fi

echo "Polybar launched..."
