#!/usr/bin/env bash

# Script to toggle Polybar visibility

# Path to your existing Polybar launch script
POLYBAR_LAUNCH_SCRIPT="$HOME/.config/polybar/scripts/launch.sh"

if pgrep -x polybar >/dev/null; then
    # Polybar is running, so stop it
    polybar-msg cmd quit
else
    # Polybar is not running, so start it
    if [ -f "$POLYBAR_LAUNCH_SCRIPT" ]; then
        # Execute the launch script in the background
        "$POLYBAR_LAUNCH_SCRIPT" &
    else
        echo "Error: Polybar launch script not found at $POLYBAR_LAUNCH_SCRIPT" >&2
    fi
fi
