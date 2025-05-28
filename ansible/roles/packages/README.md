# Packages Role

This role installs and configures packages for Arch Linux systems, with conditional installation based on the system environment (bare metal vs virtualized).

## Features

- **Automatic Virtualization Detection**: Uses `systemd-detect-virt` to determine if running on bare metal or in a VM
- **Conditional GPU Package Installation**: Installs appropriate graphics drivers based on environment
- **Guest Utilities**: Automatically installs and enables guest utilities for VMs (VirtualBox, KVM, VMware, Hyper-V)
- **AUR Support**: Installs yay and AUR packages
- **Service Management**: Enables required system services
- **User Group Management**: Adds users to appropriate groups

## GPU Package Selection

All systems get the base X11 packages (`xorg-server`, `xorg-xinit`, `xorg-xauth`, `mesa`) installed via the main package list. Additional GPU-specific drivers are installed based on the detected environment:

**Note**: This role handles GPU driver package installation. For AMD Polaris GPUs, the `boot` role also automatically detects and applies kernel parameter workarounds (`amdgpu.reset_method=0 amdgpu.runpm=0`) to fix scheduler spam issues.

### Bare Metal Systems (AMD RX 580 and similar)

When `systemd-detect-virt -v` returns `"none"`, the following additional packages are installed:

- `xf86-video-amdgpu` - AMD GPU DDX driver
- `vulkan-radeon` - Vulkan API support for AMD GPUs
- `lib32-mesa`, `lib32-vulkan-radeon` - 32-bit support for Steam/Wine
- `nvtop` - GPU monitoring tool
- `corectrl` - GUI tool for GPU monitoring and overclocking

### Virtual Machines

When running in any VM environment, the appropriate driver packages are installed based on the detected platform:

**KVM/QEMU** (`kvm`):

- `xf86-video-qxl` - QXL driver for KVM/QEMU virtualized environments

**VirtualBox** (`oracle`) and **VMware** (`vmware`):

- `xf86-video-vmware` - VMware driver (VirtualBox's VMSVGA emulates VMware SVGA)

**Hyper-V** (`microsoft`):

- No additional driver packages needed (uses mesa software rendering)

## Supported VM Platforms

The role automatically detects and configures:

- **VirtualBox** (`oracle`): Installs `virtualbox-guest-utils` and enables `vboxservice.service`
- **KVM/QEMU** (`kvm`): Installs `qemu-guest-agent` and enables `qemu-guest-agent.service`
- **VMware** (`vmware`): Installs `open-vm-tools` and enables `vmtoolsd.service`
- **Hyper-V** (`microsoft`): Installs `hyperv` and enables multiple Hyper-V services

## Variables

### Package Lists

- `pacman_packages`: Main list of packages to install (includes base X11 packages)
- `gpu_packages_baremetal`: Additional GPU packages for bare metal systems
- `gpu_packages_vm_kvm`: Additional GPU packages for KVM/QEMU virtual machines
- `gpu_packages_vm_vmware_compatible`: Additional GPU packages for VirtualBox and VMware virtual machines
- `aur_packages`: General AUR packages

### Service and User Configuration

- `services`: List of systemd services to enable
- `user_groups`: List of groups to add the user to
- `username`: Username for group membership and AUR operations

## Usage

The role is designed to be used as part of the main Ansible playbook:

```yaml
- name: Configure packages
  hosts: localhost
  become: true
  roles:
    - packages
```

## Testing

You can test the virtualization detection logic without installing packages:

```bash
ansible-playbook test-gpu-detection.yml
```

This will show which packages would be installed based on your current environment.

## Examples

### Bare Metal Output

```
Virtualization platform: none
Would install additional GPU packages: [xf86-video-amdgpu, vulkan-radeon, lib32-mesa, lib32-vulkan-radeon, radeontop, amdgpu_top, corectrl]
```

### VM Output

```
Virtualization platform: kvm
Would install additional GPU packages: [xf86-video-qxl]

Virtualization platform: oracle
Would install additional GPU packages: [xf86-video-vmware]

Virtualization platform: vmware
Would install additional GPU packages: [xf86-video-vmware]

Virtualization platform: microsoft
Would install additional GPU packages: []
```

## Notes

- **GPU Configuration**: This role installs GPU driver packages, while the `boot` role handles GPU-specific kernel parameters
- **AMD Polaris GPUs**: If you have an AMD Polaris GPU (RX 470/480/570/580/590), both roles work together:
  - This role installs the necessary AMD GPU packages (`xf86-video-amdgpu`, `vulkan-radeon`, etc.)
  - The `boot` role automatically detects Polaris GPUs and applies kernel workarounds for scheduler issues
- **Virtualization Detection**: Uses `systemd-detect-virt` to determine the appropriate driver packages for your environment
