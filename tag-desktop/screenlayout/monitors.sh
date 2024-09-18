#!/bin/sh
# Supports both ubuntu and EndeavourOS

SINGLE_MONITOR=DisplayPort-1

xrandr --output "$SINGLE_MONITOR" --primary --mode 5120x1440 --pos 0x0 --rotate normal
