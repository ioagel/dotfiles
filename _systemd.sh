#!/usr/bin/env bash

set -e

# Common utility functions
# shellcheck disable=SC1091
source ./xdg_local/lib/utils.sh

SYSTEMD_SERVICES=("$@")

if [ ${#SYSTEMD_SERVICES[@]} -gt 0 ]; then
    log "Performing systemd post-activation steps..."
    if sudo systemctl daemon-reload; then
        log "Reloaded systemd daemon."
    else
        error "Failed to reload systemd daemon."
    fi

    for service in "${SYSTEMD_SERVICES[@]}"; do
        service_file_path="/etc/systemd/system/$service"
        if [ -f "$service_file_path" ]; then
            log "Enabling systemd service '$service'..."
            # Use --now to enable and start, or just enable if you prefer manual start
            if sudo systemctl enable "$service"; then
                log "Enabled '$service'."
            else
                # Don't exit script, maybe just needs manual intervention
                warning "Failed to enable '$service'. It might already be enabled or have issues."
            fi
            # Optional: Start the service
            # log "Starting systemd service '$service'..."
            # if sudo systemctl start "$service"; then
            #     log "Started '$service'."
            # else
            #     warning "Failed to start '$service'. It might already be running or have issues."
            # fi
        else
            warning "Skipping systemd service '$service': File not found at '$service_file_path'."
        fi
    done
fi
