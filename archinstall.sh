#!/usr/bin/env bash

#==============================================================================
# Arch Linux Installation Script
#==============================================================================
#
# DESCRIPTION:
#   This script automates the installation of Arch Linux with BTRFS subvolumes
#   and optional LUKS encryption. It supports both interactive disk selection
#   and command-line specification of partitions.
#
# WIFI: Connect to a network, using: # iwctl --passphrase PASSPHRASE station DEVICE connect SSID
# Console Font: # setfont ter-132b
#
# REQUIREMENTS:
#   - UEFI boot mode
#   - Internet connection
#   - Booted from Arch Linux installation media
#
# USAGE:
#   sudo ./archinstall.sh [OPTIONS]
#
# OPTIONS:
#   -e PARTITION     EFI partition (e.g., /dev/sda1)
#   -b PARTITION     Boot partition (required with encryption, e.g., /dev/sda2)
#   -r PARTITION     Root partition (e.g., /dev/sda3 or /dev/sdb1)
#   -S               Skip formatting the EFI partition (use when it's already formatted)
#
# EXAMPLES:
#   # Interactive mode:
#   sudo ./archinstall.sh
#
#   # Encrypted setup with specific partitions:
#   sudo ./archinstall.sh -e /dev/sda1 -b /dev/sda2 -r /dev/sdb1
#
#   # Non-encrypted setup with specific partitions:
#   sudo ./archinstall.sh -e /dev/sda1 -r /dev/sda2
#
#   # Using existing EFI partition (skip formatting):
#   sudo ./archinstall.sh -e /dev/sda1 -b /dev/sda2 -r /dev/sdb1 -S
#
# FEATURES:
#   - UEFI boot with GRUB bootloader
#   - BTRFS filesystem with optimized subvolumes
#   - Optional LUKS encryption
#   - Snapper for system snapshots
#   - Ansible-based post-installation configuration
#
# WORKFLOW:
#   1. Check prerequisites (root, UEFI mode)
#   2. Install required dependencies
#   3. Configure partitioning (interactive or from command line)
#   4. Optional disk encryption setup
#   5. Create and mount filesystems
#   6. Install base system packages
#   7. Configure system settings (hostname, users, etc.)
#   8. Set up bootloader and encryption (if enabled)
#   9. Finalize with Ansible configuration
#
# NOTE: This script will format specified partitions. Use with caution!
#==============================================================================

set -euo pipefail

# DEFAULTS (Change these as needed)
SYSTEM_HOSTNAME="${SYSTEM_HOSTNAME:-archlinux}"
USER_NAME="${USER_NAME:-ioangel}"
USER_FULL_NAME="${USER_FULL_NAME:-Ioannis Angelakopoulos}"

# Partition override variables
EFI_PARTITION=""
BOOT_PARTITION=""
ROOT_PARTITION=""
SKIP_EFI_FORMAT=false

TIMEZONE="${TIMEZONE:-Europe/Athens}" # Default timezone only for installing, ansible will set it later
KEYMAP="${KEYMAP:-us}"                # Default keymap only for installing, ansible will set it later

# Function to clean up any existing LUKS containers and mounts
cleanup() {
    info "Cleaning up any existing LUKS containers and mounts..."

    # Unmount any mounted filesystems
    umount -R /mnt 2>/dev/null || true

    # Close any open LUKS containers
    for mapper in /dev/mapper/crypt*; do
        if [ -e "$mapper" ]; then
            cryptsetup close "${mapper##*/}" 2>/dev/null || true
        fi
    done
}

while getopts ":e:b:r:S" OPT; do
    case ${OPT} in
    e) EFI_PARTITION="${OPTARG}" ;;
    b) BOOT_PARTITION="${OPTARG}" ;;
    r) ROOT_PARTITION="${OPTARG}" ;;
    S) SKIP_EFI_FORMAT=true ;;
    *) error "Invalid option: -${OPT}" ;;
    esac
done

# Color variables
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Text formatting
BOLD='\033[1m'
UNDERLINE='\033[4m'

# Message functions
info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Function to display error messages
error() {
    echo -e "${RED}[ERROR] $1${NC}" >&2
    exit 1
}

# Check if running as root
check_root() {
    if [ "$(id -u)" -ne 0 ]; then
        error "This script must be run as root"
    fi
}

# Check if the system is booted in UEFI mode
check_uefi() {
    info "Checking for UEFI mode..."
    if [ ! -d "/sys/firmware/efi/efivars" ]; then
        error "UEFI mode not detected. This script requires UEFI. Please ensure you are booted in UEFI mode."
    fi
    success "UEFI mode detected."
}

# Function to check and install dependencies
check_and_install_deps() {
    info "Checking and installing essential dependencies..."

    # Install gum
    if ! command -v gum &>/dev/null; then
        pacman -Sy --noconfirm --needed gum || error "Failed to install gum. Please install it manually and re-run the script."
        success "gum installed successfully."
    fi

    # Install git
    if ! command -v git &>/dev/null; then
        pacman -Sy --noconfirm --needed git || error "Failed to install git. Please install it manually and re-run the script."
        success "git installed successfully."
    fi

    # Placeholder for installing other essential packages like git and vim
    # This will be handled by the main pacstrap command later,
    # but we ensure gum is available for the UI components first.
}

download_dotfiles() {
    # Check if dotfiles directory exists
    if [ ! -d /tmp/dotfiles ]; then
        info "Downloading dotfiles..."
        git clone https://github.com/ioagel/dotfiles.git /tmp/dotfiles
        success "Dotfiles downloaded successfully."
    fi
}

# Function to check if a disk is in use
check_disk_usage() {
    local disk=$1
    # Check if any partition of the disk is mounted
    if mount | grep -q "^$disk"; then
        return 1
    fi
    # Check if the disk is being used by LVM
    if pvs | grep -q "^$disk"; then
        return 1
    fi
    # Check if the disk is being used by mdadm
    if mdadm --detail --scan 2>/dev/null | grep -q "$disk"; then
        return 1
    fi
    return 0
}

# Function to check if a disk is USB
is_usb_disk() {
    local disk=$1
    # Check if the disk is a USB device by looking at the device path
    if [[ "$disk" =~ /dev/sd[a-z]$ ]]; then
        # Check if it's a USB device by looking at the device path
        if [ -e "/sys/block/$(basename "$disk")/device/removable" ]; then
            if [ "$(cat "/sys/block/$(basename "$disk")/device/removable")" = "1" ]; then
                return 0
            fi
        fi
        # Alternative check using udev
        if udevadm info --query=property --name="$disk" | grep -q "ID_BUS=usb"; then
            return 0
        fi
    fi
    return 1
}

# Function to get disk information
get_disk_info() {
    local disk=$1
    local size
    local type="Internal"
    local model

    # Get disk size
    size=$(lsblk -dn -o SIZE "$disk")

    # Get disk model
    model=$(lsblk -dn -o MODEL "$disk" | sed 's/^[ \t]*//')

    # Check if it's a USB disk
    if is_usb_disk "$disk"; then
        type="USB"
    fi

    echo "$disk ($size, $type, $model)"
}

# Function to select disks for EFI/boot and root partitions
select_partition_disks() {
    # If we're using explicit partitions, skip the interactive selection
    if [[ -n "$EFI_PARTITION" ]]; then
        info "Using user-specified partitions"

        # Determine parent disks
        if [[ "$ENABLE_ENCRYPTION" = true ]]; then
            if [[ -z "$BOOT_PARTITION" ]]; then
                error "Boot partition (-b) must be specified when encryption is enabled"
            fi
            if [[ -z "$ROOT_PARTITION" ]]; then
                error "Root partition (-r) must be specified when encryption is enabled"
            fi

            # Determine parent disks from partitions
            EFI_BOOT_DISK=$(lsblk -no PKNAME "/dev/$(basename "$EFI_PARTITION")" | xargs -I{} echo "/dev/{}")
            ROOT_DISK=$(lsblk -no PKNAME "/dev/$(basename "$ROOT_PARTITION")" | xargs -I{} echo "/dev/{}")
        else
            if [[ -z "$ROOT_PARTITION" ]]; then
                error "Root partition (-r) must be specified"
            fi

            # For non-encrypted setup, just need to determine disks
            EFI_BOOT_DISK=$(lsblk -no PKNAME "/dev/$(basename "$EFI_PARTITION")" | xargs -I{} echo "/dev/{}")
            ROOT_DISK=$(lsblk -no PKNAME "/dev/$(basename "$ROOT_PARTITION")" | xargs -I{} echo "/dev/{}")
        fi

        # Verify partitions exist
        for part in "$EFI_PARTITION" "$BOOT_PARTITION" "$ROOT_PARTITION"; do
            if [[ -n "$part" && ! -b "/dev/$(basename "$part")" ]]; then
                error "Partition $part does not exist"
            fi
        done

        # Using the specified partitions directly
        EFI_PART="/dev/$(basename "$EFI_PARTITION")"
        if [[ -n "$BOOT_PARTITION" ]]; then
            BOOT_PART="/dev/$(basename "$BOOT_PARTITION")"
        else
            BOOT_PART=""
        fi
        ROOT_PART="/dev/$(basename "$ROOT_PARTITION")"

        success "Using specified partitions:"
        success "EFI partition: $EFI_PART"
        [[ -n "$BOOT_PART" ]] && success "Boot partition: $BOOT_PART"
        success "Root partition: $ROOT_PART"
        return
    fi

    # Original interactive selection logic
    info "Scanning for available disks..."
    # Get a list of disks with their sizes and types
    mapfile -t disks < <(lsblk -dplnx SIZE -o NAME | awk '$1~/^\/dev\/(sd[a-z]|nvme[0-9]n[0-9]|vd[a-z])$/{print $1}' | while read -r disk; do get_disk_info "$disk"; done)

    if [ ${#disks[@]} -eq 0 ]; then
        error "No suitable disks found. Please check your hardware."
    fi

    if [ "$ENABLE_ENCRYPTION" = true ]; then
        info "Please select the disk for EFI and boot partitions (recommended: USB drive):"
        EFI_BOOT_DISK=$(printf '%s\n' "${disks[@]}" | gum choose | awk '{print $1}')

        if ! check_disk_usage "$EFI_BOOT_DISK"; then
            error "Selected disk $EFI_BOOT_DISK is currently in use. Please unmount any partitions or stop using the disk."
        fi

        # Remove the selected disk from the list for root partition selection
        mapfile -t remaining_disks < <(printf '%s\n' "${disks[@]}" | grep -v "^$EFI_BOOT_DISK")

        info "Please select the disk for the encrypted root partition:"
        ROOT_DISK=$(printf '%s\n' "${remaining_disks[@]}" | gum choose | awk '{print $1}')

        if ! check_disk_usage "$ROOT_DISK"; then
            error "Selected disk $ROOT_DISK is currently in use. Please unmount any partitions or stop using the disk."
        fi
    else
        info "Please select the disk for installation:"
        EFI_BOOT_DISK=$(printf '%s\n' "${disks[@]}" | gum choose | awk '{print $1}')

        if ! check_disk_usage "$EFI_BOOT_DISK"; then
            error "Selected disk $EFI_BOOT_DISK is currently in use. Please unmount any partitions or stop using the disk."
        fi

        ROOT_DISK="$EFI_BOOT_DISK"
    fi

    success "Selected disks:"
    success "EFI/Boot disk: $EFI_BOOT_DISK ($(get_disk_info "$EFI_BOOT_DISK"))"
    success "Root disk: $ROOT_DISK ($(get_disk_info "$ROOT_DISK"))"
}

# Function to configure encryption
configure_encryption() {
    info "Configuring disk encryption..."
    if gum confirm "Do you want to enable disk encryption? (Recommended)"; then
        ENABLE_ENCRYPTION=true
        success "Disk encryption will be enabled."

        info "Please enter the encryption passphrase:"
        while true; do
            ENCRYPTION_PASSWORD=$(gum input --password --placeholder "Enter passphrase")
            if [ -z "$ENCRYPTION_PASSWORD" ]; then
                warning "Passphrase cannot be empty. Please try again."
                continue
            fi

            info "Please confirm the encryption passphrase:"
            local confirm_password
            confirm_password=$(gum input --password --placeholder "Confirm passphrase")

            if [ "$ENCRYPTION_PASSWORD" == "$confirm_password" ]; then
                success "Encryption passphrase confirmed."
                break
            else
                warning "Passphrases do not match. Please try again."
                continue
            fi
        done
    else
        ENABLE_ENCRYPTION=false
        ENCRYPTION_PASSWORD=""
        warning "Disk encryption will NOT be enabled."
    fi
}

# Function to prepare disk for partitioning
prepare_disk() {
    local disk=$1
    info "Preparing disk $disk for partitioning..."

    # Unmount all partitions of the disk
    info "Unmounting any mounted partitions..."
    for partition in $(lsblk -no NAME "$disk" | grep -v "^$disk$"); do
        if mount | grep -q "$partition"; then
            umount -f "/dev/$partition" 2>/dev/null || true
        fi
    done

    # Clear any existing partition table and create new GPT
    info "Creating new GPT partition table..."
    sgdisk --zap-all "$disk"
    sgdisk --clear "$disk"
    sgdisk --mbrtogpt "$disk"

    # Force kernel to reread partition table
    partprobe "$disk"

    success "Disk $disk prepared successfully"
}

# Function to get root partition size
get_root_partition_size() {
    local disk=$1
    local total_size
    local size_in_gb

    # Get total disk size in GB
    total_size=$(lsblk -dn -o SIZE "$disk" | sed 's/G//')

    if gum confirm "Do you want to use the entire disk ($total_size GB) for the root partition?"; then
        echo "100%"
    else
        while true; do
            size_in_gb=$(gum input --placeholder "Enter size in GB (max $total_size)")
            if [[ "$size_in_gb" =~ ^[0-9]+$ ]] && [ "$size_in_gb" -le "$total_size" ]; then
                echo "${size_in_gb}G"
                break
            else
                warning "Please enter a valid number between 1 and $total_size"
            fi
        done
    fi
}

# Function to setup btrfs subvolumes
setup_btrfs_subvolumes() {
    local root_partition=$1
    local mount_point=$2
    local mount_opts
    info "Creating Btrfs subvolumes..."

    mount_opts="noatime,ssd,compress=zstd,space_cache=v2,discard=async"

    # Mount the root partition temporarily to create subvolumes
    mount "$root_partition" "$mount_point"

    # Create subvolumes
    btrfs subvolume create "$mount_point/@"
    btrfs subvolume create "$mount_point/@home"
    btrfs subvolume create "$mount_point/@cache"
    btrfs subvolume create "$mount_point/@tmp"
    btrfs subvolume create "$mount_point/@log"
    btrfs subvolume create "$mount_point/@spool"
    btrfs subvolume create "$mount_point/@images"
    btrfs subvolume create "$mount_point/@docker"
    btrfs subvolume create "$mount_point/@snapshots"

    # Set the @ subvolume as default for rollback compatibility
    # Get the subvolume ID of @ and set it as default
    local root_subvol_id
    root_subvol_id=$(btrfs subvolume list "$mount_point" | grep -E '\s@$' | awk '{print $2}')
    btrfs subvolume set-default "$root_subvol_id" "$mount_point"

    # Unmount the root partition
    umount "$mount_point"

    # Mount the root subvolume (@ is now default, so no subvol= needed)
    mount -o "$mount_opts" "$root_partition" "$mount_point"

    # Create mount points for subvolumes
    mkdir -p "$mount_point"/{home,var/cache,var/tmp,var/log,var/spool,var/lib/libvirt/images,var/lib/docker,.snapshots}

    # Mount all other subvolumes with proper options
    mount -o "$mount_opts,subvol=@home" "$root_partition" "$mount_point/home"
    mount -o "$mount_opts,subvol=@cache" "$root_partition" "$mount_point/var/cache"
    mount -o "$mount_opts,subvol=@tmp" "$root_partition" "$mount_point/var/tmp"
    mount -o "$mount_opts,subvol=@log" "$root_partition" "$mount_point/var/log"
    mount -o "$mount_opts,subvol=@spool" "$root_partition" "$mount_point/var/spool"
    mount -o "$mount_opts,subvol=@images" "$root_partition" "$mount_point/var/lib/libvirt/images"
    mount -o "$mount_opts,subvol=@docker" "$root_partition" "$mount_point/var/lib/docker"
    mount -o "$mount_opts,subvol=@snapshots" "$root_partition" "$mount_point/.snapshots"

    # Set proper permissions for /var/tmp
    chmod 1777 "$mount_point/var/tmp"

    success "Btrfs subvolumes created and mounted successfully"
}

# Function to mount EFI and boot partitions
mount_efi_boot() {
    local efi_partition=$1
    local boot_partition=$2
    local mount_point=$3
    info "Mounting EFI and boot partitions..."

    # Create mount points
    mkdir -p "$mount_point/efi"
    if [ -n "$boot_partition" ]; then
        mkdir -p "$mount_point/boot"
    fi

    # Mount EFI partition
    mount "$efi_partition" "$mount_point/efi"

    # Mount boot partition if it exists
    if [ -n "$boot_partition" ]; then
        mount "$boot_partition" "$mount_point/boot"
    fi

    success "EFI and boot partitions mounted successfully"
}

# Function to create partitions
create_partitions() {
    info "Creating partitions..."

    if [ "$ENABLE_ENCRYPTION" = true ]; then
        # Check if we're using pre-defined partitions
        if [[ -n "$EFI_PARTITION" ]]; then
            # Use pre-defined partitions
            EFI_PART="/dev/$(basename "$EFI_PARTITION")"
            BOOT_PART="/dev/$(basename "$BOOT_PARTITION")"
            ROOT_PART="/dev/$(basename "$ROOT_PARTITION")"

            # Skip disk preparation since we're using existing partitions
            info "Using existing partitions, skipping disk preparation"

            # Format partitions (conditionally for EFI)
            info "Formatting partitions..."
            if [[ "$SKIP_EFI_FORMAT" != true ]]; then
                info "Formatting EFI partition..."
                mkfs.fat -F32 -n EFI "$EFI_PART"
            else
                info "Skipping EFI partition formatting as requested"
            fi

            # Format boot partition
            mkfs.ext4 -F -L boot "$BOOT_PART"

            # Set up encryption on root partition
            info "Setting up encryption..."
            # Wipe any existing filesystem signatures
            wipefs -a "$ROOT_PART"
            # Force overwrite any existing LUKS header
            cryptsetup luksFormat --force-password "$ROOT_PART" <<<"$ENCRYPTION_PASSWORD"
            cryptsetup open "$ROOT_PART" cryptroot <<<"$ENCRYPTION_PASSWORD"

            # Format encrypted root
            mkfs.btrfs -f -L root /dev/mapper/cryptroot

            # Create and mount Btrfs subvolumes
            setup_btrfs_subvolumes "/dev/mapper/cryptroot" "/mnt"

            # Mount EFI and boot partitions
            mount_efi_boot "$EFI_PART" "$BOOT_PART" "/mnt"
        else
            # Original partitioning logic
            # Prepare both disks
            prepare_disk "$EFI_BOOT_DISK"
            prepare_disk "$ROOT_DISK"

            # Create partitions on EFI/boot disk
            info "Creating EFI and boot partitions on $EFI_BOOT_DISK"
            parted "$EFI_BOOT_DISK" mkpart primary fat32 1MiB 1024MiB
            parted "$EFI_BOOT_DISK" set 1 esp on
            parted "$EFI_BOOT_DISK" mkpart primary ext4 1024MiB 2048MiB

            # Get root partition size
            ROOT_SIZE=$(get_root_partition_size "$ROOT_DISK")

            # Create encrypted partition on root disk
            info "Creating encrypted partition on $ROOT_DISK"
            parted "$ROOT_DISK" mkpart primary btrfs 1MiB "$ROOT_SIZE"

            # Force kernel to reread partition table
            partprobe "$ROOT_DISK"

            # Set up encryption
            info "Setting up encryption..."
            # Wipe any existing filesystem signatures
            wipefs -a "${ROOT_DISK}1"
            # Force overwrite any existing LUKS header
            cryptsetup luksFormat --force-password "${ROOT_DISK}1" <<<"$ENCRYPTION_PASSWORD"
            cryptsetup open "${ROOT_DISK}1" cryptroot <<<"$ENCRYPTION_PASSWORD"

            # Format partitions with force flag
            info "Formatting partitions..."
            mkfs.fat -F32 -n EFI "${EFI_BOOT_DISK}1"
            mkfs.ext4 -F -L boot "${EFI_BOOT_DISK}2"
            mkfs.btrfs -f -L root /dev/mapper/cryptroot

            # Create and mount Btrfs subvolumes
            setup_btrfs_subvolumes "/dev/mapper/cryptroot" "/mnt"

            # Mount EFI and boot partitions
            mount_efi_boot "${EFI_BOOT_DISK}1" "${EFI_BOOT_DISK}2" "/mnt"
        fi
    else
        # Non-encrypted setup
        if [[ -n "$EFI_PARTITION" ]]; then
            # Use pre-defined partitions
            EFI_PART="/dev/$(basename "$EFI_PARTITION")"
            ROOT_PART="/dev/$(basename "$ROOT_PARTITION")"

            # Skip disk preparation since we're using existing partitions
            info "Using existing partitions, skipping disk preparation"

            # Format partitions (conditionally for EFI)
            info "Formatting partitions..."
            if [[ "$SKIP_EFI_FORMAT" != true ]]; then
                info "Formatting EFI partition..."
                mkfs.fat -F32 -n EFI "$EFI_PART"
            else
                info "Skipping EFI partition formatting as requested"
            fi

            # Format root partition
            mkfs.btrfs -f -L root "$ROOT_PART"

            # Create and mount Btrfs subvolumes
            setup_btrfs_subvolumes "$ROOT_PART" "/mnt"

            # Mount EFI partition
            mount_efi_boot "$EFI_PART" "" "/mnt"
        else
            # Original partitioning logic
            # Prepare single disk
            prepare_disk "$EFI_BOOT_DISK"

            # Create partitions on single disk
            info "Creating partitions on $EFI_BOOT_DISK"
            parted "$EFI_BOOT_DISK" mkpart primary fat32 1MiB 1024MiB
            parted "$EFI_BOOT_DISK" set 1 esp on

            # Get root partition size
            ROOT_SIZE=$(get_root_partition_size "$EFI_BOOT_DISK")

            parted "$EFI_BOOT_DISK" mkpart primary btrfs 1024MiB "$ROOT_SIZE"

            # Force kernel to reread partition table
            partprobe "$EFI_BOOT_DISK"

            # Format partitions with force flag
            info "Formatting partitions..."
            mkfs.fat -F32 -n EFI "${EFI_BOOT_DISK}1"
            mkfs.btrfs -f -L root "${EFI_BOOT_DISK}2"

            # Create and mount Btrfs subvolumes
            setup_btrfs_subvolumes "${EFI_BOOT_DISK}2" "/mnt"

            # Mount EFI partition
            mount_efi_boot "${EFI_BOOT_DISK}1" "" "/mnt"
        fi
    fi

    success "Partitions created and mounted successfully"
}

# Function to detect CPU vendor
detect_cpu_vendor() {
    if grep -q "vendor_id.*AMD" /proc/cpuinfo; then
        echo "amd"
    elif grep -q "vendor_id.*Intel" /proc/cpuinfo; then
        echo "intel"
    else
        echo "vm"
    fi
}

# Function to perform basic system installation
install_base_system() {
    info "Starting basic system installation..."

    # Sync package database
    info "Syncing package database..."
    pacman -Syy

    # Setup reflector
    info "Setting up reflector..."
    reflector --protocol http --latest 10 --sort rate --save /etc/pacman.d/mirrorlist

    # Detect CPU vendor and set microcode package
    CPU_VENDOR=$(detect_cpu_vendor)
    case $CPU_VENDOR in
    "amd")
        MICROCODE="amd-ucode"
        ;;
    "intel")
        MICROCODE="intel-ucode"
        ;;
    *)
        MICROCODE=""
        ;;
    esac

    # Install base system
    info "Installing base system..."
    pacstrap /mnt base base-devel linux linux-headers linux-lts linux-lts-headers \
        linux-firmware $MICROCODE btrfs-progs grub grub-btrfs snapper snap-pac efibootmgr \
        neovim networkmanager gvfs exfatprogs dosfstools e2fsprogs man-db man-pages texinfo \
        openssh git reflector wget cryptsetup wpa_supplicant terminus-font sudo iptables-nft \
        mkinitcpio ansible rsync python-passlib inotify-tools

    # Generate fstab
    info "Generating fstab..."
    genfstab -U /mnt >>/mnt/etc/fstab

    # Edit fstab to remove subvol=/@ from root filesystem for rollback compatibility
    # Even though we mounted without subvol=/@, genfstab still detects and adds it
    info "Editing fstab for rollback compatibility..."
    sed -i '/[[:space:]]\/[[:space:]]/s/,subvol=\/@//g' /mnt/etc/fstab
    sed -i '/[[:space:]]\/[[:space:]]/s/subvol=\/@,//g' /mnt/etc/fstab
    sed -i '/[[:space:]]\/[[:space:]]/s/subvol=\/@[[:space:]]/ /g' /mnt/etc/fstab

    success "Basic system installation completed"
}

# Function to collect system configuration
collect_system_config() {
    local system_hostname
    local user_name
    local user_full_name

    info "Collecting system configuration..."

    # Get hostname
    system_hostname=$(gum input --placeholder "Enter system hostname (default: ${SYSTEM_HOSTNAME})")
    if [ -n "$system_hostname" ]; then
        SYSTEM_HOSTNAME="$system_hostname"
    fi

    # Get username
    user_name=$(gum input --placeholder "Enter username (default: ${USER_NAME})")
    if [ -n "$user_name" ]; then
        USER_NAME="$user_name"
    fi

    # Get user full name
    user_full_name=$(gum input --placeholder "Enter your full name (default: ${USER_FULL_NAME})" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
    if [ -n "$user_full_name" ]; then
        USER_FULL_NAME="$user_full_name"
    fi

    # Get user password (required)
    while true; do
        USER_PASSWORD=$(gum input --password --placeholder "Enter user password (required)")
        if [ -n "$USER_PASSWORD" ]; then
            info "Please confirm the password:"
            local confirm_password
            confirm_password=$(gum input --password --placeholder "Confirm password")

            if [ "$USER_PASSWORD" == "$confirm_password" ]; then
                break
            else
                warning "Passwords do not match. Please try again."
            fi
        else
            warning "Password cannot be empty. Please try again."
        fi
    done

    success "System configuration collected"
}

# Copy dotfiles to home directory
copy_dotfiles_to_chroot_home() {
    local username="${1:-root}"
    local source_dir=/tmp/dotfiles/
    local dest_dir

    # Determine the destination directory
    if [[ "$username" == "root" ]]; then
        dest_dir="/mnt/$username"
    else
        dest_dir="/mnt/home/$username"
    fi

    if [[ ! -d "$dest_dir" ]]; then
        error "Home directory for $username does not exist."
    fi

    info "Copying dotfiles to home directory of $username..."
    rsync -a --delete "$source_dir" "${dest_dir}/.dotfiles/"
    # Change ownership to the user, if not root
    if [[ "$username" != "root" ]]; then
        # we need to chown inside the chroot environment
        arch-chroot /mnt bash -c "chown -R $username:$username /home/$username/.dotfiles/"
    fi
    success "Dotfiles copied to $username home directory"
}

# Function to run Ansible install playbook in chroot
setup_with_ansible() {
    info "Running Ansible Install playbook in chroot..."

    # Build ansible-playbook command with conditional variables
    local ansible_cmd="ansible-playbook install.yml -e user_password='$USER_PASSWORD'"

    # Add optional variables only if they are set
    [ -n "$SYSTEM_HOSTNAME" ] && ansible_cmd="$ansible_cmd -e hostname='$SYSTEM_HOSTNAME'"
    [ -n "$USER_NAME" ] && ansible_cmd="$ansible_cmd -e username='$USER_NAME'"
    [ -n "$USER_FULL_NAME" ] && ansible_cmd="$ansible_cmd -e \"user_full_name='$USER_FULL_NAME'\""

    # Add encryption variables for boot role
    # We need to use the JSON format for the boolean variables because Ansible
    # doesn't support boolean values in the command line
    if [ "$ENABLE_ENCRYPTION" = true ]; then
        ansible_cmd="$ansible_cmd -e '{\"enable_encryption\": true}'"

        # Use the actual root partition provided via command line
        if [[ -n "$ROOT_PARTITION" ]]; then
            # Use exactly what the user provided, preserving the partition number
            encrypted_device="/dev/$(basename "$ROOT_PARTITION")"
            info "Using specified encrypted device: $encrypted_device"
        else
            # Only use ROOT_DISK with suffix if no explicit partition was provided
            encrypted_device="${ROOT_DISK}1"
            info "Using default encrypted device: $encrypted_device"
        fi

        ansible_cmd="$ansible_cmd -e encrypted_device='$encrypted_device'"
        ansible_cmd="$ansible_cmd -e encryption_password='$ENCRYPTION_PASSWORD'"
    else
        ansible_cmd="$ansible_cmd -e '{\"enable_encryption\": false}'"
    fi

    # ansible cmd only for testing, bypassing the gum choices
    # ansible_cmd="ansible-playbook install.yml -e user_password='thrylos' -e '{\"enable_encryption\": true}' -e encrypted_device='/dev/vda1' -e encryption_password='thrylos'"

    # Run ansible playbook in chroot
    arch-chroot /mnt bash -c "cd /root/.dotfiles/ansible && \
        ansible-galaxy install -r requirements.yml && \
        $ansible_cmd"

    success "Ansible playbook completed"
}

# Main script execution starts here
# (We will add more functions and calls below)

# Clear the screen
clear

# Display the title
echo -e "${BLUE}${BOLD}Arch Linux Installation Script${NC}"
echo -e "${BLUE}${BOLD}==============================${NC}"
echo

# Check if running as root
check_root

# Check if system is in UEFI mode
check_uefi

# Check and install dependencies
check_and_install_deps

# Clean up any existing state
cleanup

# Set keymap and time
loadkeys "$KEYMAP"
timedatectl set-timezone "$TIMEZONE"
timedatectl set-ntp true

# Download dotfiles
download_dotfiles
cd /tmp/dotfiles

# Show warning about destructive operations
echo -e "\n${RED}${BOLD}WARNING: DESTRUCTIVE OPERATION${NC}"
echo -e "${RED}This script will ${BOLD}FORMAT${NC}${RED} the selected partitions and any existing data will be ${BOLD}PERMANENTLY LOST${NC}${RED}.${NC}"
echo -e "${RED}Make sure you have ${BOLD}BACKED UP${NC}${RED} any important data before proceeding.${NC}"
echo

if ! gum confirm "Do you understand the risks and want to proceed?"; then
    error "Installation aborted by user."
fi

# Configure encryption
configure_encryption

# Select partitions/disks
select_partition_disks

# Create partitions and filesystems
create_partitions

sleep 2
clear

# Collect system configuration
collect_system_config

# Install base system
install_base_system

# Copy dotfiles to home directory of root
copy_dotfiles_to_chroot_home "root"

# Run Ansible install playbook in chroot
setup_with_ansible

# Copy dotfiles to home directory of $USER_NAME, now that the user has been created by Ansible
copy_dotfiles_to_chroot_home "$USER_NAME"

# Restore from Borg
source ./scripts/borg-restore-function.sh

# Remove .dotfiles from root home directory, we don't need it anymore
info "Removing .dotfiles from root home directory..."
rm -rf /mnt/root/.dotfiles

# Unmount the partitions
info "Unmounting partitions..."
umount -R /mnt

# Installation is complete
echo
info "Installation complete. Reboot to the freshly installed system  and log in as user: '$USER_NAME'."
info "Change to the ~/.dotfiles directory and run the following script: ./post-install.sh"
echo

exit 0
