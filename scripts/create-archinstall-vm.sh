#!/bin/bash
set -euo pipefail

VM_NAME="archinstall-dotfiles"
MEMORY=8192
VCPUS=4
DISK_SIZE="40G"
BRIDGE="br0"
ISO_DIR="/var/lib/libvirt/isos"
ISO_BASE_URL="https://geo.mirror.pkgbuild.com/iso/latest"
ISO_DATE=$(date +'%Y.%m.01')  # First day of current month
ISO_FILENAME="archlinux-${ISO_DATE}-x86_64.iso"
ISO_PATH="$ISO_DIR/$ISO_FILENAME"
DISK_PATH="/var/lib/libvirt/images/${VM_NAME}.qcow2"
NVRAM_PATH="/var/lib/libvirt/qemu/nvram/${VM_NAME}_VARS.fd"
OVMF_CODE="/usr/share/edk2/x64/OVMF_CODE.secboot.4m.fd"
OVMF_VARS_TEMPLATE="/usr/share/edk2/x64/OVMF_VARS.4m.fd"

# Check for required commands
check_dependencies() {
    local missing=()
    for cmd in lsusb virt-install qemu-img virsh curl; do
        if ! command -v "$cmd" &> /dev/null; then
            missing+=("$cmd")
        fi
    done

    if [[ ${#missing[@]} -ne 0 ]]; then
        echo "❌ Missing required dependencies:"
        for cmd in "${missing[@]}"; do
            echo "  - $cmd"
        done
        echo "Please install them with:"
        echo "  sudo pacman -S ${missing[*]//lsusb/usbutils}"
        exit 1
    fi
}

# Download the latest Arch Linux ISO
download_latest_iso() {
    echo "🌐 Checking for Arch Linux ISO for ${ISO_DATE}..."
    local latest_iso_url="$ISO_BASE_URL/$ISO_FILENAME"
    local checksum_url="$ISO_BASE_URL/sha256sums.txt"

    # Create ISO directory if it doesn't exist
    mkdir -p "$ISO_DIR"

    # Download the ISO
    echo "⬇️  Downloading Arch Linux ISO for ${ISO_DATE}..."
    if ! curl -L -o "$ISO_PATH.part" --progress-bar "$latest_iso_url"; then
        echo "❌ Failed to download ISO from $latest_iso_url"
        # Fall back to previous month if current month's ISO isn't available yet
        local prev_month=$(date -d "$(date +%Y-%m-01) -1 month" +'%Y.%m.01')
        echo "⚠️  Trying previous month's ISO (${prev_month})..."
        ISO_DATE="$prev_month"
        ISO_FILENAME="archlinux-${ISO_DATE}-x86_64.iso"
        ISO_PATH="$ISO_DIR/$ISO_FILENAME"
        latest_iso_url="$ISO_BASE_URL/$ISO_FILENAME"

        if ! curl -L -o "$ISO_PATH.part" --progress-bar "$latest_iso_url"; then
            echo "❌ Failed to download ISO from $latest_iso_url"
            return 1
        fi
    fi

    # Verify checksum
    echo "🔍 Verifying checksum..."
    local checksum
    checksum=$(curl -s "$checksum_url" | grep "$ISO_FILENAME" | cut -d' ' -f1)

    if ! echo "$checksum  $ISO_PATH.part" | sha256sum --check --status; then
        echo "❌ Checksum verification failed"
        rm -f "$ISO_PATH.part"
        return 1
    fi

    # Move the downloaded file into place
    mv "$ISO_PATH.part" "$ISO_PATH"
    echo "✅ Successfully downloaded and verified $ISO_FILENAME"
}

check_dependencies

# Create ISO directory if it doesn't exist
if [[ ! -d "$ISO_DIR" ]]; then
    echo "Creating ISO directory..."
    sudo mkdir -p "$ISO_DIR"
    sudo chown "${USER}":libvirt "$ISO_DIR"
    chmod 775 "$ISO_DIR"
fi

# Check if we should download the latest ISO
if [[ -f "$ISO_PATH" ]]; then
    read -p "ISO found at $ISO_PATH. Download latest version? [y/N] " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        download_latest_iso
    fi
else
    download_latest_iso
fi

# Check if ISO exists after potential download
if [[ ! -f "$ISO_PATH" ]]; then
    echo "❌ No ISO file available. Please download it manually and place it in $ISO_DIR/"
    exit 1
fi

# Create disk if needed
if [[ ! -f "$DISK_PATH" ]]; then
  echo "Creating disk image..."
  qemu-img create -f qcow2 "$DISK_PATH" "$DISK_SIZE"
fi

# Create NVRAM if needed
if [[ ! -f "$NVRAM_PATH" ]]; then
  echo "Copying UEFI vars..."
  sudo cp "$OVMF_VARS_TEMPLATE" "$NVRAM_PATH"
  sudo chown qemu:qemu "$NVRAM_PATH"
fi

# Step 1: List all USB devices
echo "🖧 Connected USB Devices:"
usb_devices=()
mapfile -t usb_devices < <(lsusb)

if [[ ${#usb_devices[@]} -eq 0 ]]; then
  echo "❌ No USB devices found."
  exit 1
fi

for i in "${!usb_devices[@]}"; do
  echo "[$i] ${usb_devices[$i]}"
done

# Step 2: Ask for selection
read -r -p "Enter space-separated indices of USB devices to passthrough (e.g. 0 2): " -a selected_indices

# Step 3: Extract vendor:product IDs
usb_args=()
for i in "${selected_indices[@]}"; do
  if [[ "$i" =~ ^[0-9]+$ ]] && [[ $i -ge 0 && $i -lt ${#usb_devices[@]} ]]; then
    line="${usb_devices[$i]}"
    id=$(echo "$line" | grep -oP '[0-9a-f]{4}:[0-9a-f]{4}')
    if [[ -n "$id" ]]; then
      usb_args+=(--host-device "usb:${id}")
    fi
  else
    echo "⚠️ Invalid index: $i"
  fi
done

# Launch VM
echo "Starting VM with the following USB devices:"
for arg in "${usb_args[@]}"; do
    echo "  $arg"
done

# Step 4: Launch VM
virt-install \
  --name "$VM_NAME" \
  --memory $MEMORY \
  --vcpus $VCPUS \
  --cpu host-passthrough \
  --os-variant archlinux \
  --boot uefi \
  --disk path="$DISK_PATH",format=qcow2,bus=virtio,discard=unmap \
  --disk path="$ISO_PATH",device=cdrom,bus=sata \
  --network bridge="$BRIDGE",model=virtio \
  --graphics spice \
  --video qxl \
  --sound ich9 \
  --channel unix,target_type=virtio,name=org.qemu.guest_agent.0 \
  --channel spicevmc,target_type=virtio,name=com.redhat.spice.0 \
  --controller type=usb,model=qemu-xhci \
  --controller type=scsi,model=virtio-scsi \
  --input type=tablet,bus=usb \
  --rng /dev/urandom \
  --memballoon model=virtio \
  "${usb_args[@]}" \
  --boot loader="$OVMF_CODE",loader.readonly=yes,loader.secure=yes,nvram="$NVRAM_PATH" \
  --noautoconsole

echo "✅ VM '$VM_NAME' created with selected USB devices passed through."
echo "To connect to the VM:"
echo "  virt-viewer --connect qemu:///system $VM_NAME"
echo "Or use virt-manager:"
echo "  virt-manager --connect qemu:///system"
