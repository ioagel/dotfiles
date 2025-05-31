#!/bin/bash
# Post-install configuration script
# Runs post-install roles that require systemd services

set -euo pipefail

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
log_info "- [future roles as added]"
echo ""
log_info "Note: You may be prompted for your sudo password"
echo ""

# Run the playbook
cd "$DOTFILES_DIR"
if ansible-playbook -i ansible/inventory.yml "$PLAYBOOK_PATH"; then
    echo ""
    log_success "============================================="
    log_success "  POST-INSTALL CONFIGURATION COMPLETED!"
    log_success "============================================="
else
    echo ""
    log_error "Post-install configuration failed! Check errors above"
    exit 1
fi
