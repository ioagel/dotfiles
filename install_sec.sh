#!/usr/bin/env bash
# Setup sensitive configuration files

# Common utility functions
# shellcheck source=/dev/null
source ./xdg_local/lib/utils.sh

check_command "1password"
check_command "op"

log "Setting up sensitive configuration files..."
# Ensure 1Password CLI is signed in (you might have a helper function for this)
# op signin # This would typically be done interactively before running the script fully

# --- Populate ~/.item_expirations.txt ---
ITEM_EXPIRATIONS_VAULT="Private"                        # The vault where the item is stored
ITEM_EXPIRATIONS_TITLE="Dotfiles Item Expirations File" # The title of the 1P item

log "Fetching content for ~/.item_expirations.txt from 1Password..."
if op read "op://$ITEM_EXPIRATIONS_VAULT/$ITEM_EXPIRATIONS_TITLE/notes" >~/.item_expirations.txt; then
    log ~/.item_expirations.txt created successfully.
    chmod 600 ~/.item_expirations.txt
else
    warning "Failed to fetch or create ~/.item_expirations.txt from 1Password. Please ensure the item exists and you are signed in."
fi

# --- Populate ~/.config/fetch_cron_jobs/config ---
CRON_SCRIPT_CONFIG_VAULT="Infra"
CRON_SCRIPT_CONFIG_TITLE="Fetch Cron Jobs Script Config"
CONFIG_DIR_CRON_SCRIPT="$HOME/.config/fetch_cron_jobs"
CONFIG_FILE_CRON_SCRIPT="$CONFIG_DIR_CRON_SCRIPT/config"

log "Fetching content for $CONFIG_FILE_CRON_SCRIPT from 1Password..."
mkdir -p "$CONFIG_DIR_CRON_SCRIPT"
if op read "op://$CRON_SCRIPT_CONFIG_VAULT/$CRON_SCRIPT_CONFIG_TITLE/notes" >"$CONFIG_FILE_CRON_SCRIPT"; then
    log "$CONFIG_FILE_CRON_SCRIPT created successfully."
    chmod 600 "$CONFIG_FILE_CRON_SCRIPT"
else
    warning "Failed to fetch or create $CONFIG_FILE_CRON_SCRIPT from 1Password."
fi

log "Sensitive configuration setup complete."
