# Boot Role

This role configures the boot system for Arch Linux, including GRUB bootloader and mkinitcpio with optional encryption support.

## Features

- **GRUB Configuration**: Sets up GRUB bootloader with customizable settings
- **Encryption Support**: Uses an existing USB key for encrypted Btrfs `/boot`; no key is embedded in initramfs
- **UUID-based Device References**: Automatically detects and uses UUID for encrypted devices (more reliable than device paths)
- **mkinitcpio Setup**: Configures initramfs with appropriate hooks for encrypted/non-encrypted systems
- **EFI Support**: Preserves an already-tested encrypted GRUB EFI loader; installs GRUB for non-encrypted systems

## Variables

### Encryption Variables

- `enable_encryption`: Enable encryption support (default: `false`)
- `encrypted_device`: Path to encrypted device (e.g., `/dev/sda1`) - UUID will be automatically detected
- `luks_usb_keyfile`: Existing key file on `/efi` (required when encryption is enabled)
- `encrypted_grub_efi_loader`: Existing, tested GRUB EFI loader on `/efi` (required)
- `encrypted_grub_early_config`: Existing, tested early GRUB config on `/efi` (required)

### GRUB Variables

- `grub_timeout`: GRUB menu timeout in seconds (default: `5`)
- `grub_default`: Default GRUB entry (default: `0`) - First entry in main menu
- `grub_disable_submenu`: Disable GRUB submenus (default: `true`) - Shows all kernels in main menu with regular `linux` kernel appearing first, `linux-lts` second
- `grub_cmdline_linux_default`: Default kernel parameters (default: `"nowatchdog loglevel=3 quiet pcie_port_pm=off pcie_aspm.policy=performance"`) - Includes stability and hardware compatibility fixes for desktop/workstation use

### mkinitcpio Variables

- `mkinitcpio_modules`: Kernel modules to include in initramfs (default: `["btrfs", "crc32c"]` for Btrfs filesystem support with hardware-accelerated checksums)
- `mkinitcpio_binaries`: Additional binaries to include (default: `[]`)
- `mkinitcpio_files`: Additional files to include in initramfs (default: `[]`). Never include the USB key.
- `mkinitcpio_hooks_encrypted`: Hooks for encrypted systems (includes `grub-btrfs-overlayfs` for snapshot booting)
- `mkinitcpio_hooks_normal`: Hooks for non-encrypted systems (includes `grub-btrfs-overlayfs` for snapshot booting)

## Usage

### Basic Usage (No Encryption)

```yaml
- hosts: localhost
  roles:
    - role: boot
```

### With Custom GRUB Settings

```yaml
- hosts: localhost
  roles:
    - role: boot
      vars:
        grub_timeout: 10
        grub_cmdline_linux_default: "nowatchdog loglevel=3 quiet pcie_port_pm=off pcie_aspm.policy=performance rd.systemd.show_status=false"
```

### Existing encrypted Btrfs boot

```yaml
- hosts: localhost
  roles:
    - role: boot
      vars:
        enable_encryption: true
        encrypted_device: "/dev/nvme1n1p2"
        luks_usb_keyfile: "/efi/luks-key-<LUKS-UUID>.bin"
        encrypted_grub_efi_loader: "/efi/EFI/GRUB-BTRFS/grubx64.efi"
        encrypted_grub_early_config: "/efi/EFI/GRUB-BTRFS/early.cfg"
```

## Notes

- The role automatically detects the UUID of encrypted devices for reliable booting
- Encrypted mode requires `/boot` inside the Btrfs root, an already enrolled USB key, and a tested GRUB EFI loader and early config. It checks these before changing boot files.
- The role does not generate a key, enroll a LUKS slot, or reinstall the encrypted GRUB EFI loader. Provisioning and EFI updates are separate, recovery-critical operations.
- The kernel unlocks root using `cryptkey=/dev/disk/by-uuid/<EFI-UUID>:vfat:/<keyfile>`; the initramfs contains USB/FAT modules but no key.
- Direct snapshot boot has been tested. Permanent `snapper rollback` with the encrypted GRUB path still needs separate validation.
- The `grub-btrfs-overlayfs` hook is included for snapshot booting support with grub-btrfs
- Hardware-accelerated checksums are enabled with the `crc32c` module for Btrfs
- Microcode updates are automatically included for CPU security and stability
- PCIe power management is disabled (`pcie_port_pm=off pcie_aspm.policy=performance`) to prevent network disconnection issues common with Intel I225-V and other Ethernet controllers
- Hardware watchdog is disabled (`nowatchdog`) to prevent unexpected reboots during heavy workloads on desktop/workstation systems
- AMD Polaris GPUs are automatically detected and workarounds (`amdgpu.reset_method=0 amdgpu.runpm=0`) are applied to fix scheduler spam issues
