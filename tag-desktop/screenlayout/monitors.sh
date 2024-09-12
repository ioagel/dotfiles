#!/bin/sh
# Supports both ubuntu and EndeavourOS

# igpu ports when rx580 is used in vfio
LEFT_MONITOR=HDMI-A-0
RIGHT_MONITOR=DisplayPort-0
# left monitor connected to rx580
LEFT_EXTERNAL_MONITOR=DP-1-3

output=$(xrandr --listactivemonitors | awk '{print $4}')

if echo "$output" | grep -qE "^HDMI-A-1$" && echo "$output" | grep -qE "^DisplayPort-1$"; then
  # rx580 ports
  LEFT_MONITOR=HDMI-A-1
  RIGHT_MONITOR=DisplayPort-1
fi

if echo "$output" | grep -qE "^HDMI-A-2$" && echo "$output" | grep -qE "^DisplayPort-2$"; then
  # igpu ports
  LEFT_MONITOR=HDMI-A-2
  RIGHT_MONITOR=DisplayPort-2
fi

if [ "$1" = left_external ]; then
  OLD_LEFT_MONITOR=$LEFT_MONITOR

  # rx580 left and igpu right monitor
  LEFT_MONITOR=$LEFT_EXTERNAL_MONITOR
  echo "Do not forget to reload i3, after this script! (Win+Shift+R)"
fi

xrandr --output "$LEFT_MONITOR" --primary --mode 3840x2160 --pos 0x0 --rotate normal \
  --output "$RIGHT_MONITOR" --mode 1920x1200 --scale 1.5x1.5 --pos 3840x146 --rotate normal

if [ -n "$OLD_LEFT_MONITOR" ]; then
  # Deactivate unused connection
  xrandr --output "$OLD_LEFT_MONITOR" --off 2>/dev/null
  exit 0 # we exit here to prevent inactivating our left external monitor
fi

xrandr --output "$LEFT_EXTERNAL_MONITOR" --off 2>/dev/null
