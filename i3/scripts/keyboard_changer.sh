#!/bin/bash

current_lang=$(setxkbmap -print | awk -F"+" '/xkb_symbols/ {print $2}')

if [ $current_lang = 'us' ]; then
  setxkbmap gr
  echo gr > ~/.i3/scripts/keyboard_language
fi


if [ $current_lang = 'gr' ]; then
  setxkbmap us
  echo us > ~/.i3/scripts/keyboard_language
fi

killall -USR1 i3status
