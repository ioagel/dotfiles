#!/usr/bin/env bash
# shellcheck disable=SC1090

# Terminate already running bar instances
# If all your bars have ipc enabled, you can use
polybar-msg cmd quit
# Otherwise you can use the nuclear option:
# killall -q polybar

# Wait until the processes have been shut down
while pgrep -u $UID -x polybar >/dev/null; do sleep 1; done

# source the active theme if it exists
ACTIVE_THEME_FILE="$HOME/.config/themes/active-theme.sh"
[ -f "$ACTIVE_THEME_FILE" ] && source "$ACTIVE_THEME_FILE"

# Launch polybar
polybar main &

echo "Polybar launched..."
