# Boot Role

This role configures the boot system for Arch Linux, including GRUB bootloader and mkinitcpio with optional encryption support.

## Features

- **GRUB Configuration**: Sets up GRUB bootloader with customizable settings
- **Encryption Support**: Configures LUKS encryption with keyfile for automatic unlocking
- **UUID-based Device References**: Automatically detects and uses UUID for encrypted devices (more reliable than device paths)
- **mkinitcpio Setup**: Configures initramfs with appropriate hooks for encrypted/non-encrypted systems
- **EFI Support**: Installs GRUB for UEFI systems

## Variables

### Encryption Variables

- `enable_encryption`: Enable encryption support (default: `false`)
- `encrypted_device`: Path to encrypted device (e.g., `/dev/sda1`) - UUID will be automatically detected
- `encryption_password`: Password for LUKS encryption

### GRUB Variables

- `grub_timeout`: GRUB menu timeout in seconds (default: `5`)
- `grub_default`: Default GRUB entry (default: `0`) - First entry in main menu
- `grub_disable_submenu`: Disable GRUB submenus (default: `true`) - Shows all kernels in main menu with regular `linux` kernel appearing first, `linux-lts` second
- `grub_cmdline_linux_default`: Default kernel parameters (default: `"nowatchdog loglevel=3 quiet pcie_port_pm=off pcie_aspm.policy=performance"`) - Includes stability and hardware compatibility fixes for desktop/workstation use

### mkinitcpio Variables

- `mkinitcpio_modules`: Kernel modules to include in initramfs (default: `["btrfs", "crc32c"]` for Btrfs filesystem support with hardware-accelerated checksums)
- `mkinitcpio_binaries`: Additional binaries to include (default: `[]`)
- `mkinitcpio_files`: Additional files to include in initramfs (default: `[]`). For encrypted systems, the keyfile is automatically added.
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

### With Encryption

```yaml
- hosts: localhost
  roles:
    - role: boot
      vars:
        enable_encryption: true
        encrypted_device: "/dev/sda1"
        encryption_password: "your_luks_password"
```

### Advanced Configuration

```yaml
- hosts: localhost
  roles:
    - role: boot
      vars:
        enable_encryption: true
        encrypted_device: "/dev/nvme0n1p2"
        encryption_password: "your_luks_password"
        grub_timeout: 3
        grub_cmdline_linux_default: "nowatchdog loglevel=3 quiet pcie_port_pm=off pcie_aspm.policy=performance rd.systemd.show_status=false"
        mkinitcpio_modules: ["btrfs", "crc32c", "nvme"]
```

## Notes

- The role automatically detects the UUID of encrypted devices for reliable booting
- For encrypted systems, a keyfile is generated and stored in `/efi/crypto_keyfile_<UUID>.bin`
- **Boot Partition Encryption**: This role assumes `/boot` partition is **unencrypted** (common setup). GRUB's `cryptodisk` and `luks` modules are only needed if GRUB must read from encrypted storage. With unencrypted `/boot`, GRUB can access kernel and initramfs files without decryption support.
- The `grub-btrfs-overlayfs` hook is included for snapshot booting support with grub-btrfs
- Hardware-accelerated checksums are enabled with the `crc32c` module for Btrfs
- Microcode updates are automatically included for CPU security and stability
- PCIe power management is disabled (`pcie_port_pm=off pcie_aspm.policy=performance`) to prevent network disconnection issues common with Intel I225-V and other Ethernet controllers
- Hardware watchdog is disabled (`nowatchdog`) to prevent unexpected reboots during heavy workloads on desktop/workstation systems
- AMD Polaris GPUs are automatically detected and workarounds (`amdgpu.reset_method=0 amdgpu.runpm=0`) are applied to fix scheduler spam issues
