# Snapshots Role

This Ansible role configures automatic snapshots and rollbacks for Arch Linux using `snapper`, `grub-btrfs`, and `snap-pac`.

**⚠️ Important**: This role runs during the **post-install phase** (after first boot with systemd) and requires the **boot role** to have been executed during installation for full rollback compatibility.

## Features

- **Dual Configuration Support**: Separate snapshot configs for root filesystem and home directory
- **Snapper Configuration**: Automatic timeline and number-based snapshots
- **GRUB-BTRFS Integration**: Boot from snapshots directly via GRUB menu
- **Snap-PAC Integration**: Automatic snapshots before and after pacman operations
- **Enhanced Management Scripts**: Comprehensive snapshot management with safety features
- **Automatic Cleanup**: Intelligent cleanup that respects different config types
- **Arch Wiki Compliance**: Proper handling of existing @snapshots subvolumes
- **Rollback Compatibility**: Works with GRUB rollback compatibility fixes from boot role

## Prerequisites

### Required Components

This role **requires** the following to be configured beforehand:

1. **BTRFS filesystem** with `@` and `@home` subvolumes
2. **Boot role execution** during installation (handles GRUB rollback compatibility)
3. **Systemd environment** (runs post-install, not in chroot)

### GRUB Rollback Compatibility

The **boot role** automatically configures rollback compatibility by:

- Removing `rootflags=subvol=@` auto-generation from `/etc/grub.d/10_linux`
- Installing ALPM hooks to maintain compatibility after GRUB updates
- Setting proper default subvolume configuration

Without these fixes, rollbacks would fail because kernel command line parameters override snapper's subvolume changes.

## Components

### Snapper

- **Root config**: Full-featured with timeline snapshots (hourly, daily, monthly, yearly)
- **Home config**: Conservative manual-only approach (no automatic snapshots)
- **Initial snapshot**: Automatically creates "Initial system setup" snapshot for root config
- Automatic cleanup based on age and limits
- Proper handling of existing @snapshots subvolumes per Arch Wiki
- Excludes `.snapshots` from locate database indexing (`updatedb.conf`)

### GRUB-BTRFS

- Enables booting from snapshots via GRUB menu
- Automatically detects and lists available root snapshots
- Updates GRUB configuration when snapshots are created/deleted

### Snap-PAC

- Creates snapshots before and after pacman operations
- Provides rollback capability for package changes
- Integrates with snapper's number-based cleanup

## Configuration Variables

### Basic Settings

- `snapper_config_name`: Root snapper configuration name (default: "root")
- `snapper_subvolume`: Target subvolume (default: "/")
- `snapper_allow_users`: Users allowed to manage snapshots for both root and home configs (default: "{{ username }}")

### Home Directory Settings

- `snapper_config_name_home`: Home snapper configuration name (default: "home")
- `snapper_subvolume_home`: Home subvolume path (default: "/home")

### Timeline Snapshots (Root Only)

- `snapper_timeline_min_age`: Minimum age before cleanup in seconds (default: "1800")
- `snapper_timeline_limit_hourly`: Number of hourly snapshots to keep (default: "5")
- `snapper_timeline_limit_daily`: Number of daily snapshots to keep (default: "7")
- `snapper_timeline_limit_weekly`: Number of weekly snapshots to keep (default: "0")
- `snapper_timeline_limit_monthly`: Number of monthly snapshots to keep (default: "0")
- `snapper_timeline_limit_yearly`: Number of yearly snapshots to keep (default: "0")

### System Services

- `snapshots_systemd_services`: List of systemd services to enable (default includes snapper-timeline.timer, snapper-cleanup.timer, grub-btrfsd.service)

**Note**: Additional configuration options like space limits, number cleanup settings, and empty pre-post-pair cleanup are hardcoded in the templates with sensible defaults.

## Management Commands

The role installs enhanced management scripts with dual-config support:

### snap-manager

Enhanced snapshot management script with safety features:

```bash
# Create snapshots
snap-manager create "My important changes"                    # Root config (default)
snap-manager create "Important files" --config home          # Home config
snap-manager create "System backup" --config all             # Both configs

# List snapshots
snap-manager list                                             # Root config
snap-manager list --config home                              # Home config  
snap-manager list --config all                               # Both configs

# Delete snapshots (with confirmation and validation)
snap-manager delete 42 --config root
snap-manager delete 15 --config home

# Safe rollback with automatic safety snapshots
snap-manager rollback 41 --config root                       # Creates safety snapshot first
snap-manager rollback 23 --config home

# Intelligent cleanup (respects config differences)
snap-manager cleanup --config all                            # Smart cleanup for both configs
snap-manager cleanup --config root                           # Timeline + number cleanup
snap-manager cleanup --config home                           # Number cleanup only
```

### User Aliases

The role creates convenient bash aliases:

```bash
# List all snapshots
snapshots                    # Shows both root and home configs

# Create snapshots
snap "Description"           # Create root snapshot
snap-home "Description"      # Create home snapshot
```

**Note**: Zsh aliases are configured separately in the user's personal zsh configuration (`~/.zsh/configs/post/aliases.zsh`) and provide the same functionality.

### grub-snapshot-boot

Enhanced GRUB snapshot management:

```bash
# Update GRUB configuration with latest snapshots
grub-snapshot-boot update

# List available snapshot boot entries
grub-snapshot-boot list-boot

# Check grub-btrfs status and configuration
grub-snapshot-boot status
```

## How to Use

### Creating Snapshots

1. **Automatic snapshots** are created:
   - **Root**: Before/after package operations (snap-pac) + timeline basis (hourly, daily, etc.)
   - **Home**: Only before/after package operations (snap-pac) - no timeline snapshots

2. **Manual snapshots**:

   ```bash
   # Before system changes
   snap-manager create "Before kernel update" --config root
   
   # Before important file changes  
   snap-manager create "Before project cleanup" --config home
   
   # Both at once
   snap-manager create "Before major system change" --config all
   ```

### Viewing Snapshots

```bash
# View all snapshots (both configs)
snapshots

# View specific config
snap-manager list --config root
snap-manager list --config home

# Or use snapper directly
sudo snapper -c root list
sudo snapper -c home list
```

### Rolling Back

#### Enhanced Safety Features

- **Automatic validation**: Checks if snapshot exists before proceeding
- **Safety snapshots**: Creates backup snapshot before rollback (optional)
- **Detailed confirmation**: Shows snapshot details and impact warnings
- **Smart error handling**: Validates inputs and provides helpful error messages
- **Rollback compatibility**: Uses `--ambit classic` syntax for proper BTRFS rollback handling

#### Prerequisites for Rollbacks

**⚠️ Critical**: Root filesystem rollbacks require the **boot role** to have configured GRUB rollback compatibility during installation. Without this, rollbacks will fail because kernel command line parameters (`rootflags=subvol=@`) override snapper's subvolume changes.

#### Method 1: Using the enhanced management script (Recommended)

```bash
# Root filesystem rollback (requires boot role compatibility fixes)
snap-manager rollback 42 --config root

# Home directory rollback (always works)
snap-manager rollback 23 --config home
```

The script automatically uses `snapper --ambit classic` for proper rollback handling.

#### Method 2: Direct snapper command

```bash
# Root filesystem rollback (requires boot role compatibility fixes)
sudo snapper --ambit classic -c root rollback 42

# Home directory rollback
sudo snapper --ambit classic -c home rollback 23
```

#### Method 3: Boot from snapshot (root only)

1. Reboot the system
2. Select "Arch Linux snapshots" from GRUB menu
3. Choose the desired snapshot
4. Boot into the snapshot
5. If satisfied, make the snapshot permanent:

   ```bash
   sudo snapper --ambit classic -c root rollback 42
   ```

**Note**: Methods 1 and 2 require reboot to see root filesystem changes. Method 3 boots directly into the snapshot state.

### Cleanup

**Automatic cleanup** is handled by systemd timers:

- **snapper-timeline.timer**: Handles timeline cleanup according to configured limits
- **snapper-cleanup.timer**: Handles number-based cleanup for package snapshots
- **Root config**: Both timeline and number cleanup enabled
- **Home config**: Number cleanup only (since `TIMELINE_CREATE="no"`, but `TIMELINE_CLEANUP="yes"` for any manual timeline snapshots)

Manual cleanup:

```bash
# Clean all configs intelligently
snap-manager cleanup --config all

# Clean specific config
snap-manager cleanup --config root    # Timeline + number
snap-manager cleanup --config home    # Number only
```

## Configuration Philosophy

### Root Config (Full-Featured)

- **Timeline snapshots**: Enabled for system state preservation
- **Automatic cleanup**: Both timeline and number-based
- **Package snapshots**: Automatic via snap-pac
- **GRUB integration**: Bootable snapshots available

### Home Config (Conservative)

- **Timeline snapshots**: Disabled (`TIMELINE_CREATE="no"`)
- **Manual snapshots**: Only when explicitly requested
- **Package snapshots**: Automatic via snap-pac (important files before updates)
- **Cleanup**: Number cleanup enabled (`NUMBER_CLEANUP="yes"`)
- **Background comparison**: Enabled for change tracking

## Important Notes

### Rollback Considerations

- **Root rollbacks**: Affect system files, require reboot to see changes
- **Home rollbacks**: Affect user data, immediate effect
- **Safety snapshots**: Always offered before rollback operations
- **Validation**: All operations validate snapshot existence and user permissions

### Storage Requirements

- Snapshots use copy-on-write (CoW), so they're space-efficient
- Root timeline snapshots may accumulate over time
- Home snapshots are created sparingly (manual + package operations only)
- Monitor disk usage with enhanced status commands

### Dual Config Benefits

- **Separation of concerns**: System vs. user data snapshots
- **Flexible retention**: Different policies for different needs
- **Reduced clutter**: Home doesn't get flooded with timeline snapshots
- **Focused rollbacks**: Target specific areas without affecting others

## Troubleshooting

### Enhanced Status Checking

```bash
# Comprehensive status overview
grub-snapshot-boot status

# Check specific configs
snap-manager list --config all
```

### Snapshots not appearing in GRUB

1. Check grub-btrfs status:

   ```bash
   grub-snapshot-boot status
   ```

2. Update GRUB configuration:

   ```bash
   grub-snapshot-boot update
   ```

3. Manually check the service:

   ```bash
   sudo systemctl status grub-btrfsd.service
   sudo systemctl enable --now grub-btrfsd.service
   ```

### Configuration Issues

1. Verify configs exist:

   ```bash
   sudo snapper list-configs
   snap-manager list --config all
   ```

2. Check mount points:

   ```bash
   mountpoint /.snapshots
   mountpoint /home/.snapshots
   ```

### High Disk Usage

1. Check snapshot usage by config:

   ```bash
   snap-manager list --config root
   snap-manager list --config home
   sudo btrfs filesystem usage /
   ```

2. Targeted cleanup:

   ```bash
   snap-manager cleanup --config root    # Clean timeline snapshots
   snap-manager cleanup --config home    # Clean package snapshots
   ```

## Dependencies

### Ansible Integration

This role is executed via the **`post-install.yml`** playbook after the initial system installation:

```bash
# Executed after first boot with systemd
./post-install.sh
```

The role execution sequence:

1. **Installation phase**: `archinstall.sh` → `ansible/install.yml` (includes boot role)
2. **Post-install phase**: `post-install.sh` → `ansible/post-install.yml` (includes snapshots role)

This separation ensures:

- Boot role configures GRUB rollback compatibility during installation
- Snapshots role configures snapper when systemd services are available

### Package Dependencies

This role requires the following packages:

- `snapper` - Core snapshot functionality
- `grub-btrfs` - GRUB snapshot boot integration  
- `snap-pac` - Automatic pacman operation snapshots
- `inotify-tools` - grub-btrfs automatic updates
- `btrfs-assistant` (AUR) - Optional GUI management

The system must be using:

- BTRFS filesystem for root and home
- GRUB bootloader
- Systemd init system

## Advanced Recovery Tools

For specialized BTRFS recovery scenarios that go beyond standard rollback operations, additional tools are available in [`scripts/advanced-btrfs/`](../../../scripts/advanced-btrfs/).

### When You Might Need Them

- **Permanent adoption**: You've booted into a snapshot and want to make it your permanent system (instead of rolling back)
- **Complex recovery**: Standard rollback isn't suitable for your situation
- **BTRFS restructuring**: You need to convert snapshot structures to clean subvolume layouts

### Available Tools

- **`adopt-current-snapshot.sh`**: Permanently adopt a grub-btrfs booted snapshot as your main system
- **`snapshot-to-root.sh`**: Convert an adopted snapshot into a clean @ subvolume structure

**Convenient Access**: After running `setup-dotfiles.sh`, these are also available as:

- `btrfs-adopt-snapshot` (symlink to `adopt-current-snapshot.sh`)
- `btrfs-snapshot-to-root` (symlink to `snapshot-to-root.sh`)

### ⚠️ Important Notes

- These tools are **advanced and potentially dangerous**
- They modify your BTRFS filesystem structure permanently  
- They're **intentionally kept separate** from this role due to their specialized nature
- For routine snapshot management, always use the tools provided by this role (`snap-manager`, `grub-snapshot-boot`)

See the [advanced tools documentation](../../../scripts/advanced-btrfs/README.md) for detailed usage and safety information.
