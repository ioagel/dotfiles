#!/usr/bin/env bash

# Exit on error, undefined variables, and pipefail
set -eo pipefail

# Constants (change these to your preferences)
TIMEZONE="Europe/Athens"
KEYMAP="us"

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

while getopts ":d:" OPT; do
    case ${OPT} in
    d) TARGET_DISK="${OPTARG}" ;;
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
    if [ ! -d "$HOME/dotfiles" ]; then
        info "Downloading dotfiles..."
        git clone https://github.com/ioagel/dotfiles.git "$HOME/dotfiles"
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

# Function to create and mount Btrfs subvolumes
setup_btrfs_subvolumes() {
    local root_partition=$1
    local mount_point=$2
    local mount_opts
    info "Setting up Btrfs subvolumes..."

    mount_opts="noatime,ssd,compress=zstd,space_cache=v2,discard=async"

    # Mount the root partition
    mount -o "$mount_opts" "$root_partition" "$mount_point"

    # Create subvolumes
    btrfs subvolume create "$mount_point/@"
    btrfs subvolume create "$mount_point/@home"
    btrfs subvolume create "$mount_point/@cache"
    btrfs subvolume create "$mount_point/@tmp"
    btrfs subvolume create "$mount_point/@log"
    btrfs subvolume create "$mount_point/@images"
    btrfs subvolume create "$mount_point/@docker"
    btrfs subvolume create "$mount_point/@snapshots"

    # Unmount the root partition
    umount "$mount_point"

    # Mount the root subvolume
    mount -o "$mount_opts,subvol=@" "$root_partition" "$mount_point"

    # Create mount points for subvolumes
    mkdir -p "$mount_point"/{home,var/cache,var/tmp,var/log,var/lib/libvirt/images,var/lib/docker,.snapshots}

    # Mount all other subvolumes with proper options
    mount -o "$mount_opts,subvol=@home" "$root_partition" "$mount_point/home"
    mount -o "$mount_opts,subvol=@cache" "$root_partition" "$mount_point/var/cache"
    mount -o "$mount_opts,subvol=@tmp" "$root_partition" "$mount_point/var/tmp"
    mount -o "$mount_opts,subvol=@log" "$root_partition" "$mount_point/var/log"
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
    else
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
    pacstrap /mnt base base-devel linux linux-headers linux-lts linux-lts-headers linux-firmware $MICROCODE btrfs-progs grub efibootmgr neovim networkmanager gvfs exfatprogs dosfstools e2fsprogs man-db man-pages texinfo openssh git reflector wget cryptsetup wpa_supplicant terminus-font sudo iptables-nft mkinitcpio

    # Generate fstab
    info "Generating fstab..."
    genfstab -U /mnt >>/mnt/etc/fstab

    success "Basic system installation completed"
}

# Main script execution starts here
# (We will add more functions and calls below)

# Clear the screen
clear

# Initial checks
check_root
check_uefi # Call the UEFI check function
check_and_install_deps

# Clean up any existing state
cleanup

info "Initial checks passed. Starting Arch Linux installation..."

loadkeys $KEYMAP
timedatectl set-timezone $TIMEZONE
timedatectl set-ntp true

download_dotfiles

# Select the disk to install Arch Linux on if not provided as an argument
# if [ -z "$TARGET_DISK" ]; then
#     select_disk
# fi

configure_encryption   # Call the encryption configuration function
select_partition_disks # Select disks for partitioning
create_partitions      # Create the partitions
install_base_system    # Install the base system
