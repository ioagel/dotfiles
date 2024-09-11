#!/bin/sh

output=$(xrandr --listactivemonitors | awk '{print $4}')
# igpu ports
LEFT_MONITOR=HDMI-A-2
RIGHT_MONITOR=DisplayPort-2

if echo "$output" | grep -q "HDMI-A-1" && echo "$output" | grep -q "DisplayPort-1"; then
  # rx580 ports
  LEFT_MONITOR=HDMI-A-1
  RIGHT_MONITOR=DisplayPort-1
fi

xrandr --output "$LEFT_MONITOR" --primary --mode 3840x2160 --pos 0x0 --rotate normal \
  --output "$RIGHT_MONITOR" --mode 1920x1200 --scale 1.5x1.5 --pos 3840x146 --rotate normal
