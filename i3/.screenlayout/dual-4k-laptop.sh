#!/bin/sh
xrandr --output eDP --mode 1920x1080 --pos 7680x1080 --rotate normal --output HDMI-A-0 --primary --mode 3840x2160 --pos 0x0 --rotate normal --output DisplayPort-0 --mode 3840x2160 --pos 3840x0 --rotate normal --output DisplayPort-1 --off
#DISPLAY=:0.0 feh --bg-scale ~/SynologyDrive/3_Resources/wallpapers/4K/dino-reichmuth-98982-unsplash.jpg
DISPLAY=:0.0 feh --bg-fill --recursive --randomize ~/SynologyDrive/3_Resources/wallpapers/*
