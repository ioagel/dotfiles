#!/bin/bash

NOTIFY_ID_FILE="/tmp/brightness_notify_id"

if [[ -f "$NOTIFY_ID_FILE" ]]; then
    NOTIFY_ID=$(<"$NOTIFY_ID_FILE")
else
    NOTIFY_ID=0
fi

brightnessctl --min-val=2 -q set 5%+

BRIGHTNESS=$(brightnessctl -m | cut -d, -f4)

NEW_ID=$(notify-send -p -r "$NOTIFY_ID" "Brightness" "$BRIGHTNESS")

echo "$NEW_ID" > "$NOTIFY_ID_FILE"
