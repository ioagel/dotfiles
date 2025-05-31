#!/bin/bash

# adopt-current-snapshot.sh - Automatically adopt currently booted grub-btrfs snapshot
#
# This script detects when you're running from a grub-btrfs snapshot (overlay)
# and automatically adopts it as the permanent default subvolume.
#
# Usage: Run this from within a grub-btrfs booted snapshot environment

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

# Check if we're in a grub-btrfs overlay environment
ROOT_FSTYPE=$(findmnt -n -o FSTYPE /)
if [[ "$ROOT_FSTYPE" != "overlay" ]]; then
    error "Not running from a grub-btrfs snapshot overlay!"
    error "Current root filesystem type: $ROOT_FSTYPE"
    error "This script should only be run from a grub-btrfs booted snapshot."
    exit 1
fi

info "Detected grub-btrfs snapshot overlay environment"

# Try to detect which snapshot we're running from
# Method 1: Check /proc/cmdline for rootflags with snapshot path
CMDLINE_SNAPSHOT=$(sudo grep -o "subvol=@snapshots/[0-9]\+/snapshot" /proc/cmdline || true)

if [[ -n "$CMDLINE_SNAPSHOT" ]]; then
    # Extract snapshot number from rootflags
    SNAPSHOT_NUM=$(echo "$CMDLINE_SNAPSHOT" | grep -o "[0-9]\+" | head -1)
    info "Detected snapshot from /proc/cmdline: $SNAPSHOT_NUM"
else
    # Method 2: Check mount info for snapshot references
    SNAPSHOT_INFO=$(mount | grep -E "@snapshots.*snapshot" | head -1 || true)

    if [[ -n "$SNAPSHOT_INFO" ]]; then
        # Extract snapshot number from mount info
        SNAPSHOT_NUM=$(echo "$SNAPSHOT_INFO" | grep -o "snapshots/[0-9]\+/" | grep -o "[0-9]\+" | head -1)
        info "Detected snapshot from mount info: $SNAPSHOT_NUM"
    else
        # Method 3: Manual fallback
        error "Could not automatically detect which snapshot is currently booted"
        error "Please manually specify the snapshot number:"
        echo -n "Enter snapshot number: "
        read -r SNAPSHOT_NUM

        if [[ ! "$SNAPSHOT_NUM" =~ ^[0-9]+$ ]]; then
            error "Invalid snapshot number"
            exit 1
        fi
    fi
fi

if [[ -z "$SNAPSHOT_NUM" ]]; then
    error "Could not determine snapshot number"
    exit 1
fi

info "Detected snapshot number: $SNAPSHOT_NUM"

# Detect the root device (look for BTRFS mounts)
ROOT_DEVICE=""
while IFS= read -r line; do
    if [[ "$line" =~ btrfs ]]; then
        # Extract the SOURCE field and remove any subvolume specification [...]
        DEVICE=$(echo "$line" | awk '{print $2}' | sed 's/\[.*\]//')
        if [[ -b "$DEVICE" ]]; then # Check if it's actually a block device
            ROOT_DEVICE="$DEVICE"
            break
        fi
    fi
done < <(findmnt -t btrfs -n)

if [[ -z "$ROOT_DEVICE" ]]; then
    error "Could not detect BTRFS root device"
    exit 1
fi

info "Detected BTRFS device: $ROOT_DEVICE"

# Create mount point
MOUNT_POINT="/mnt/adopt-snapshot"
info "Creating mount point: $MOUNT_POINT"
sudo mkdir -p "$MOUNT_POINT"

# Mount top-level subvolume
info "Mounting top-level BTRFS subvolume..."
sudo mount -o subvolid=5 "$ROOT_DEVICE" "$MOUNT_POINT"

# Find the snapshot subvolume
SNAPSHOT_PATH="@snapshots/$SNAPSHOT_NUM/snapshot"
info "Looking for snapshot path: $SNAPSHOT_PATH"

SNAPSHOT_ID=$(sudo btrfs subvolume list "$MOUNT_POINT" | grep "path $SNAPSHOT_PATH$" | awk '{print $2}')

if [[ -z "$SNAPSHOT_ID" ]]; then
    error "Could not find snapshot $SNAPSHOT_NUM in BTRFS subvolumes"
    sudo btrfs subvolume list "$MOUNT_POINT" | grep snapshots | head -5
    sudo umount "$MOUNT_POINT"
    sudo rmdir "$MOUNT_POINT"
    exit 1
fi

info "Found snapshot ID: $SNAPSHOT_ID"

# Show current default
CURRENT_DEFAULT=$(sudo btrfs subvolume get-default "$MOUNT_POINT")
info "Current default subvolume: $CURRENT_DEFAULT"

# Confirm adoption
warn "This will permanently adopt snapshot $SNAPSHOT_NUM (ID: $SNAPSHOT_ID) as your default system"
warn "Your current default subvolume will be replaced"
echo -n "Proceed with adoption? (y/N): "
read -r response
if [[ ! "$response" =~ ^[Yy]$ ]]; then
    info "Aborting"
    sudo umount "$MOUNT_POINT"
    sudo rmdir "$MOUNT_POINT"
    exit 0
fi

# Set snapshot as default
info "Setting snapshot $SNAPSHOT_NUM as default subvolume..."
sudo btrfs subvolume set-default "$SNAPSHOT_ID" "$MOUNT_POINT"

# Make snapshot writable (critical!)
info "Making snapshot writable..."
# Use the actual snapshot path, not the mount point
sudo btrfs property set "$MOUNT_POINT/$SNAPSHOT_PATH" ro false

# Verify
info "Verifying changes..."
NEW_DEFAULT=$(sudo btrfs subvolume get-default "$MOUNT_POINT")
READONLY_STATUS=$(sudo btrfs property get "$MOUNT_POINT" ro)

echo "New default subvolume: $NEW_DEFAULT"
echo "Readonly status: $READONLY_STATUS"

# Cleanup
info "Cleaning up..."
sudo umount "$MOUNT_POINT"
sudo rmdir "$MOUNT_POINT"

success "Snapshot $SNAPSHOT_NUM successfully adopted!"
success "Snapshot is now the default subvolume and writable"
warn "REBOOT NOW and select the main GRUB entry (not snapshot entries)"

echo
echo "After reboot:"
echo "  - You'll be running snapshot $SNAPSHOT_NUM as your main system"
echo "  - Use './snapshot-to-root.sh' to clean up the structure (optional)"
echo "  - Normal snapper functionality will be restored"
