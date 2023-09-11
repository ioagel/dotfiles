#!/bin/bash

# run this with cron: 'sudo crontab -e'
# 0 7 * * * /home/ioangel/.bin/fix-intel-i225v-nic.sh
echo 1 | sudo tee "/sys/bus/pci/devices/$(lspci -D | grep 'Ethernet Controller I225-V' | awk '{print $1}')/remove" && sleep 1 && echo 1 | sudo tee /sys/bus/pci/rescan

exit 0
