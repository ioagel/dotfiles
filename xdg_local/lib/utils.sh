#!/usr/bin/env bash

# --- Logging Functions ---
log() {
    echo "[INFO] $1"
}

warning() {
    # Yellow color: \033[1;33m, Reset: \033[0m
    echo -e "\033[1;33m[WARN] $1\033[0m"
}

error() {
    # Red color: \033[1;31m, Reset: \033[0m
    echo -e "\033[1;31m[ERROR] $1\033[0m" >&2
    exit 1
}

# Helper function to check for command existence
check_command() {
    local command_name="$1"
    local msg="${2:-}"
    if ! command -v "$command_name" &>/dev/null; then
        error "Required command '$command_name' not found. $msg"
    fi
}

# Helper function to check if the system is a laptop
is_laptop() {
    # Method 1: Check DMI Chassis Type
    if [ -f /sys/class/dmi/id/chassis_type ]; then
        local chassis_type
        chassis_type=$(cat /sys/class/dmi/id/chassis_type)
        case "$chassis_type" in
        8 | 9 | 10 | 11 | 14) return 0 ;; # True, it's a laptop type
        esac
    fi

    # Method 2: Check for battery (fallback or alternative)
    for supply in /sys/class/power_supply/BAT*; do
        if [ -d "$supply" ]; then
            return 0 # True, battery found
        fi
    done

    return 1 # False, not identified as a laptop
}
