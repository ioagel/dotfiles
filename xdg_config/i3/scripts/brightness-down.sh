#!/bin/bash

# File to store the last notification ID
NOTIFY_ID_FILE="/tmp/brightness_notify_id"

# Read existing notify ID if available
if [[ -f "$NOTIFY_ID_FILE" ]]; then
    NOTIFY_ID=$(<"$NOTIFY_ID_FILE")
else
    NOTIFY_ID=0
fi

# Adjust brightness
brightnessctl --min-val=2 -q set 5%-

# Get brightness level
BRIGHTNESS=$(brightnessctl -m | cut -d, -f4)

# Send or replace notification and save new ID
NEW_ID=$(notify-send -p -r "$NOTIFY_ID" "Brightness" "$BRIGHTNESS")
echo "$NEW_ID" > "$NOTIFY_ID_FILE"
