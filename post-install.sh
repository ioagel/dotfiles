#!/usr/bin/env bash
# Post-install configuration script
# Runs post-install roles that require systemd services

set -euo pipefail

# Default values
WIFI_SSID=""
WIFI_PASSWORD=""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

# Get script directory (should be dotfiles root)
DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLAYBOOK_PATH="$DOTFILES_DIR/ansible/post-install.yml"

# Validate environment
if [ ! -f "$PLAYBOOK_PATH" ]; then
    log_error "Post-install playbook not found!"
    log_error "Expected: $PLAYBOOK_PATH"
    exit 1
fi

if ! command -v ansible-playbook >/dev/null 2>&1; then
    log_error "ansible-playbook not found!"
    log_info "Install with: pacman -S ansible"
    exit 1
fi

log_info "============================================="
log_info "  POST-INSTALL CONFIGURATION"
log_info "============================================="
echo ""

log_info "Running post-install roles that require systemd:"
log_info "- snapshots (snapper configs, service startup)"
if [ -n "$WIFI_SSID" ] && [ -n "$WIFI_PASSWORD" ]; then
    log_info "- network (including WiFi configuration for SSID: $WIFI_SSID)"
else
    log_info "- network (Ethernet only, no WiFi credentials provided)"
fi
log_info "- [future roles as added]"
echo ""
log_info "Note: You may be prompted for your sudo password"
echo ""

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --wifi-ssid=*)
            WIFI_SSID="${1#*=}"
            shift
            ;;
        --wifi-password=*)
            WIFI_PASSWORD="${1#*=}"
            shift
            ;;
        *)
            log_error "Unknown option: $1"
            exit 1
            ;;
    esac
done

# Build ansible-playbook command
ANSIBLE_CMD="ansible-playbook -i ansible/inventory.yml"

# Add WiFi credentials if provided
if [ -n "$WIFI_SSID" ] && [ -n "$WIFI_PASSWORD" ]; then
    ANSIBLE_CMD+=" -e wifi_ssid=\"$WIFI_SSID\" -e wifi_password=\"$WIFI_PASSWORD\""
elif [ -n "$WIFI_SSID" ] || [ -n "$WIFI_PASSWORD" ]; then
    log_warning "Both --wifi-ssid and --wifi-password must be provided to configure WiFi"
fi

# Run the playbook
cd "$DOTFILES_DIR"
log_info "Running: $ANSIBLE_CMD \"$PLAYBOOK_PATH\""
if eval "$ANSIBLE_CMD \"$PLAYBOOK_PATH\""; then
    log_info "Setting up dotfiles..."
    source setup-dotfiles.sh

    echo ""
    log_success "================================================================"
    log_success "  POST-INSTALL CONFIGURATION COMPLETED! Reboot to apply changes."
    log_success "================================================================"
else
    echo ""
    log_error "Post-install configuration failed! Check errors above"
    exit 1
fi
