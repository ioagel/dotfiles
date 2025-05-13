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
