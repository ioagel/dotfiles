#!/bin/sh

output=$(xrandr --listactivemonitors | awk '{print $4}')
# igpu ports when rx580 is used in vfio
LEFT_MONITOR=HDMI-A-0
RIGHT_MONITOR=DisplayPort-0

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

xrandr --output "$LEFT_MONITOR" --primary --mode 3840x2160 --pos 0x0 --rotate normal \
  --output "$RIGHT_MONITOR" --mode 1920x1200 --scale 1.5x1.5 --pos 3840x146 --rotate normal
