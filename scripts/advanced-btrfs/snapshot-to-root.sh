#!/bin/bash

# snapshot-to-root.sh - Convert adopted snapshot to new @ subvolume
#
# This script converts a currently running snapshot (set as default subvolume)
# into a proper new @ subvolume, giving you a clean structure again.
#
# Usage: Run this when you've adopted a snapshot and want to make it the new @

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

# Detect root device
ROOT_DEVICE=$(findmnt -n -o SOURCE / | head -1)
if [[ -z "$ROOT_DEVICE" ]]; then
    error "Could not detect root device"
    exit 1
fi

# Clean the device path - remove any subvolume specification [...]
ROOT_DEVICE=$(echo "$ROOT_DEVICE" | sed 's/\[.*\]//')

# Validate it's actually a block device
if [[ ! -b "$ROOT_DEVICE" ]]; then
    error "Detected device is not a block device: $ROOT_DEVICE"
    exit 1
fi

info "Detected root device: $ROOT_DEVICE"

# Create mount point
MOUNT_POINT="/mnt/snapshot-conversion"
info "Creating mount point: $MOUNT_POINT"
sudo mkdir -p "$MOUNT_POINT"

# Mount top-level subvolume (subvolid=5)
info "Mounting top-level BTRFS subvolume..."
sudo mount -o subvolid=5 "$ROOT_DEVICE" "$MOUNT_POINT"

# Check current default subvolume
info "Checking current default subvolume..."
CURRENT_DEFAULT=$(sudo btrfs subvolume get-default "$MOUNT_POINT")
echo "Current default: $CURRENT_DEFAULT"

# List current subvolumes
info "Current subvolume structure:"
sudo btrfs subvolume list "$MOUNT_POINT" | grep -E "(path @$|@snapshots.*snapshot$)" | head -10

# Get current default subvolume ID and path
DEFAULT_ID=$(echo "$CURRENT_DEFAULT" | awk '{print $2}')
DEFAULT_PATH=$(sudo btrfs subvolume list "$MOUNT_POINT" | grep "^ID $DEFAULT_ID " | awk '{print $NF}')

if [[ ! "$DEFAULT_PATH" =~ @snapshots.*snapshot$ ]]; then
    warn "Current default subvolume doesn't appear to be a snapshot: $DEFAULT_PATH"
    echo -n "Continue anyway? (y/N): "
    read -r response
    if [[ ! "$response" =~ ^[Yy]$ ]]; then
        info "Aborting"
        sudo umount "$MOUNT_POINT"
        sudo rmdir "$MOUNT_POINT"
        exit 0
    fi
fi

info "Will convert snapshot '$DEFAULT_PATH' (ID: $DEFAULT_ID) to new @ subvolume"
echo -n "Proceed? (y/N): "
read -r response
if [[ ! "$response" =~ ^[Yy]$ ]]; then
    info "Aborting"
    sudo umount "$MOUNT_POINT"
    sudo rmdir "$MOUNT_POINT"
    exit 0
fi

# Step 1: Create new @ from current working snapshot
info "Creating new @ subvolume from current snapshot..."
if [[ -d "$MOUNT_POINT/@new" ]]; then
    warn "Cleaning up existing @new subvolume..."
    sudo btrfs subvolume delete "$MOUNT_POINT/@new"
fi

# The current default is our working snapshot, create @ from it
sudo btrfs subvolume snapshot "$MOUNT_POINT/$DEFAULT_PATH" "$MOUNT_POINT/@new"

# Step 2: Delete nested subvolumes in old @ (if any)
if [[ -d "$MOUNT_POINT/@" ]]; then
    info "Checking for nested subvolumes in old @..."
    NESTED_SUBVOLS=$(sudo btrfs subvolume list "$MOUNT_POINT" | grep "top level 256" | awk '{print $NF}' || true)

    if [[ -n "$NESTED_SUBVOLS" ]]; then
        warn "Found nested subvolumes in @:"
        echo "$NESTED_SUBVOLS"

        while IFS= read -r subvol; do
            if [[ -n "$subvol" ]]; then
                info "Deleting nested subvolume: $subvol"
                sudo btrfs subvolume delete "$MOUNT_POINT/$subvol"
            fi
        done <<<"$NESTED_SUBVOLS"
    fi

    # Step 3: Delete old @ subvolume
    info "Deleting old @ subvolume..."
    sudo btrfs subvolume delete "$MOUNT_POINT/@"
else
    info "No existing @ subvolume found"
fi

# Step 4: Rename new snapshot to @
info "Renaming new subvolume to @..."
sudo mv "$MOUNT_POINT/@new" "$MOUNT_POINT/@"

# Step 5: Get new @ subvolume ID and set as default
NEW_AT_ID=$(sudo btrfs subvolume list "$MOUNT_POINT" | grep "path @$" | awk '{print $2}')
info "New @ subvolume ID: $NEW_AT_ID"

info "Setting new @ subvolume as default..."
sudo btrfs subvolume set-default "$NEW_AT_ID" "$MOUNT_POINT"

# Verify
info "Verifying new default subvolume..."
NEW_DEFAULT=$(sudo btrfs subvolume get-default "$MOUNT_POINT")
echo "New default: $NEW_DEFAULT"

# Cleanup
info "Cleaning up..."
sudo umount "$MOUNT_POINT"
sudo rmdir "$MOUNT_POINT"

success "Conversion completed successfully!"
success "Your working snapshot is now the new @ subvolume (ID: $NEW_AT_ID)"
warn "REBOOT NOW to apply changes - select the main GRUB entry (not snapshot entries)"

echo
echo "After reboot, you should have:"
echo "  - Clean @ subvolume structure"
echo "  - Your working system as the main @ subvolume"
echo "  - Normal snapper functionality restored"
