VM_NAME="archinstall-dotfiles"

# Shut down the VM if it's running
virsh destroy "$VM_NAME" 2>/dev/null || true

# Undefine the VM and remove all associated storage (disks, NVRAM)
virsh undefine "$VM_NAME" --nvram --remove-all-storage

# Optionally remove leftover disk manually (if you created it yourself)
rm -f "/data/kvm/images/${VM_NAME}.qcow2"

# Remove manually created NVRAM file if not auto-removed
rm -f "/var/lib/libvirt/qemu/nvram/${VM_NAME}_VARS.fd"
