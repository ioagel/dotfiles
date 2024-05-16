#!/usr/bin/env bash

no_monitors=$(xrandr --listactivemonitors | awk '{print $2}' | head -n 1)

if [ "$no_monitors" -eq 1 ]; then
  ~/.screenlayout/laptop.sh
elif [ "$no_monitors" -eq 2 ]; then
  ~/.screenlayout/dual-4k.sh
else
  ~/.screenlayout/dual-4k-laptop.sh
fi
