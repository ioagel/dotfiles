# Advanced BTRFS Tools

⚠️ **WARNING**: These are advanced BTRFS recovery tools that modify your filesystem structure. Use with extreme caution and only if you understand the implications.

## Scripts

### `adopt-current-snapshot.sh`

**Purpose**: Permanently adopt a grub-btrfs booted snapshot as your main system.

**Use case**: You've booted into a snapshot via GRUB and want to make it your permanent default instead of rolling back.

**What it does**:

- Detects which snapshot you're currently running from
- Sets that snapshot as the default BTRFS subvolume
- Makes the snapshot writable
- Prepares it to become your main system

**Usage**:

```bash
# Boot into a snapshot via GRUB first, then:
./adopt-current-snapshot.sh

# Or use the convenient symlink (available after running setup-dotfiles.sh):
btrfs-adopt-snapshot
```

### `snapshot-to-root.sh`

**Purpose**: Convert an adopted snapshot into a clean @ subvolume structure.

**Use case**: After adopting a snapshot, convert it to a proper new @ subvolume for cleaner organization.

**What it does**:

- Creates a new @ subvolume from the current working snapshot
- Removes the old @ subvolume structure
- Sets the new @ as the default subvolume
- Restores normal BTRFS layout

**Usage**:

```bash
# Run after adopt-current-snapshot.sh:
./snapshot-to-root.sh

# Or use the convenient symlink (available after running setup-dotfiles.sh):
btrfs-snapshot-to-root
```

## Workflow Example

1. **Problem occurs** - your system breaks after an update
2. **Boot into snapshot** - select a snapshot from GRUB boot menu
3. **Test the snapshot** - verify everything works correctly
4. **Adopt snapshot** - run `adopt-current-snapshot.sh` to make it permanent
5. **Clean structure** (optional) - run `snapshot-to-root.sh` for clean @ layout
6. **Reboot** - your system now runs from the adopted snapshot

## When NOT to Use These Scripts

- **For temporary testing** - use normal `snap-manager rollback` instead
- **For routine recovery** - standard rollback is safer and reversible
- **If you're unsure** - these operations are permanent and complex

## Safety Notes

- ✅ **Always have backups** before running these scripts
- ✅ **Test in a VM first** if possible
- ✅ **Understand BTRFS subvolumes** before proceeding
- ❌ **Don't use for routine snapshot management** - use the main snapshots role tools instead

## Integration with Main Snapshots Role

These tools complement the main [snapshots role](../../ansible/roles/snapshots/) but are intentionally kept separate due to their specialized and potentially dangerous nature.

For routine snapshot management, use:

- `snap-manager` - create, delete, list, rollback snapshots
- `grub-snapshot-boot` - manage boot entries and check status

## Convenient Access

When you run `setup-dotfiles.sh`, convenient symlinks are automatically created in `~/.local/bin` by `stow` (which is in your PATH):

- `btrfs-adopt-snapshot` → `adopt-current-snapshot.sh`
- `btrfs-snapshot-to-root` → `snapshot-to-root.sh`

This provides easy access while maintaining clear separation through the `btrfs-` prefix, making it obvious these are advanced BTRFS tools distinct from routine snapshot management.
