#!/bin/sh
# Supports both ubuntu and EndeavourOS

# rx580
SINGLE_MONITOR=DisplayPort-1
# igpu
# SINGLE_MONITOR=DisplayPort-0
# SINGLE_MONITOR=DisplayPort-2

xrandr --output "$SINGLE_MONITOR" --primary --mode 5120x1440 --pos 0x0 --rotate normal
