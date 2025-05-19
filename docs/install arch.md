# Install main PC

## Initial settings

1. Set `root` paswd so you can login with `ssh`: `passwd`
2. Login from `control` machine to new arch install
3. Set the following:

```sh
loadkeys us
timedatectl set-timezone Europe/Athens
timedatectl set-ntp true
```

## Disk Setup

### Partition Disk

```sh
lsblk
# Look at your disks, and adjust (vda is usual in libvirt, in bare metal teh naming will be different)
# NAME  MAJ:MIN RM   SIZE RO TYPE MOUNTPOINTS                              # loop0   7:0    0 846.7M  1 loop /run/archiso/airootfs                    # sr0    11:0    1   1.2G  0 rom  /run/archiso/bootmnt                     # vda   254:0    0    50G  0 disk

# Create disk partitions with: gdisk
gdisk /dev/vda
# create a GUID partition table if it does not exists (disk empty) with 'o'
# create an EFI partition of 1G: code 'ef00'
# create a Linux partition for /boot of 1G
# Create the main linux partition and choose the appropriate size
# press 'w' to save your changes

# The result of the above should look like this:
lsblk
# NAME   MAJ:MIN RM   SIZE RO TYPE MOUNTPOINTS                             
# ...
# vda    254:0    0    50G  0 disk                                        # ├─vda1 254:1    0     1G  0 part
# ├─vda2 254:1    0     1G  0 part
# └─vda3 254:2    0    48G  0 part
```

### Encrypt Main Partition

```sh
# Setup (choose a good rememberable password)
cryptsetup luksFormat /dev/vda3
# Open
cryptsetup luksOpen /dev/vda3 main # 'main' or choose any other appropriate
# Format (using btrfs)
mkfs.btrfs /dev/mapper/main
```

### BTRFS Subvolume Setup

```sh
# Mount our main partition and cd to it
mount /dev/mapper/main /mnt
cd /mnt
# Create the subvolumes
btrfs su cr @
btrfs su cr @home
btrfs su cr @cache
btrfs su cr @tmp
btrfs su cr @log
btrfs su cr @images
btrfs su cr @docker
# List the subvolumes (and verify them)
btrfs su list /mnt
# ID 256 gen 9 top level 5 path @
# ID 257 gen 9 top level 5 path @home
# ID 258 gen 9 top level 5 path @cache
# ID 259 gen 10 top level 5 path @tmp
# ID 260 gen 10 top level 5 path @log
# ID 261 gen 10 top level 5 path @images
# ID 262 gen 10 top level 5 path @docker

# Unmount /mnt
umount /mnt
# Mount our root '@' subvolume now to /mnt
mount -o noatime,ssd,compress=zstd,space_cache=v2,discard=async,subvol=@ /dev/mapper/main /mnt
# Created the needed mount points for the rest of the subvolumes
mkdir -p /mnt/{boot,efi,home,var/cache,var/tmp,var/log,var/lib/libvirt/images,var/lib/docker}
# Set the proper permissions for '/var/tmp'
chmod 1777 /mnt/var/tmp

# Mount the subvolumes
mount -o noatime,ssd,compress=zstd,space_cache=v2,discard=async,subvol=@home /dev/mapper/main /mnt/home
mount -o noatime,ssd,compress=zstd,space_cache=v2,discard=async,subvol=@cache /dev/mapper/main /mnt/var/cache
mount -o noatime,ssd,compress=zstd,space_cache=v2,discard=async,subvol=@tmp /dev/mapper/main /mnt/var/tmp
mount -o noatime,ssd,compress=zstd,space_cache=v2,discard=async,subvol=@log /dev/mapper/main /mnt/var/log
mount -o noatime,ssd,compress=zstd,space_cache=v2,discard=async,subvol=@images /dev/mapper/main /mnt/var/lib/libvirt/images                              mount -o noatime,ssd,compress=zstd,space_cache=v2,discard=async,subvol=@docker /dev/mapper/main /mnt/var/lib/docker

# Format EFI
mkfs.fat -F32 /dev/vda1 
# Mount the EFI partition 
mount /dev/vda1 /mnt/efi
# Format and mount Boot
mkfs.ext2 /dev/vda2
mount /dev/vda2 /mnt/boot
```

## Basic System Install

1. Setup `reflector` for fast mirrors:

```sh
# Greece causes me problems
reflector -c Germany -a 12 --sort rate --save /etc/pacman.d/mirrorlist
```

2. Install essential packages into new filesystem and generate fstab:

```sh
pacstrap -i /mnt base linux linux-headers linux-firmware sudo neovim
genfstab -U -p /mnt >> /mnt/etc/fstab
```

## Basic configuration of new system

1. Chroot into freshly created filesystem:

```sh
arch-chroot /mnt
```

2. Setup system locale and timezone, sync hardware clock with system clock:

```sh
ln -sf /usr/share/zoneinfo/Europe/Athens /etc/localtime # choose your timezone
hwclock --systohc
timedatectl set-ntp true
nvim /etc/locale.gen # uncomment your locales, i.e. `en_US.UTF-8` and `el_GR.UTF-8`
locale-gen
echo "LANG=en_US.UTF-8" > /etc/locale.conf # choose your locale
```

3. Setup system hostname:

```sh
echo "yourhostname" > /etc/hostname
nvim /etc/hosts
 127.0.0.1 localhost
 ::1       localhost
 127.0.1.1 yourhostname
```

4. Add new users and setup passwords:

```sh
# Main user
useradd -m -G wheel,storage,power,audio,video -s /bin/bash ioangel
# remote_admin user needed to manage machine from remote hosts
useradd -m -s /bin/bash remote_admin
passwd root
passwd ioangel
# Do not add passwd for remote_admin, can login only through ssh keys

# Add names to created users
nvim /etc/passwd
 ioangel:x:1000:1000:Ioannis Angelakopoulos:/home/ioangel:/bin/bash        remote_admin:x:1001:1001:Remote Admin:/home/remote_admin:/bin/bash
```

5. Setup `sudo`:

```sh
# Allow wheel group to run sudo
sed -i '/^# %wheel ALL=(ALL:ALL) ALL/s/^# //' /etc/sudoers
# Allow ioangel run sudo without passwd
echo "ioangel ALL=(ALL:ALL) NOPASSWD: ALL" > /etc/sudoers.d/ioangel
# Allow remote_admin run without password with sudo, only: systemctl suspend
echo "remote_admin ALL=(ALL) NOPASSWD: /usr/bin/systemctl suspend" > /etc/sudoers.d/remote_admin
# set file permissions
chmod 400 /etc/sudoers.d/ioangel
chmod 400 /etc/sudoers.d/remote_admin
```

6. Disable Copy On Write for `/var/lib/libvirt/images` to prevent excessive fragmentation.

```sh
# lsattr -d /var/lib/libvirt/images/
# ---------------------- /var/lib/libvirt/images/
chattr -VR +C /var/lib/libvirt/images/
# lsattr -d /var/lib/libvirt/images/
# ---------------C------ /var/lib/libvirt/images/
```

## Software Packages

1. Install additional useful and needed terminal packages

```sh
# Choose either amd-ucode or intel-ucode, nothing for VMs
pacman -S base-devel grub btrfs-progs grub-btrfs efibootmgr mtools exfatprogs ntfs-3g openssh git reflector amd-ucode bash-completion man-db man-pages plocate iptables-nft zip unzip htop btop tree dialog net-tools wget rsync openbsd-netcat bind lshw openvpn wireguard-tools stow tldr jq zellij step-cli eza borg networkmanager networkmanager-openvpn dhcpcd resolvconf
# lshw: Provides detailed information on the hardware of the machine
# dialog: A tool to display dialog boxes from shell scripts
# net-tools:  Configuration tools for Linux networking
# openbsd-netcat: Netcat program. OpenBSD variant.
# bind: I use dig utility for DNS resolution from this package

systemctl enable dhcpcd
systemctl enable NetworkManager
systemctl enable systemd-resolved
systemctl enable sshd
systemctl enable fstrim.timer
```

2. Install Desktop packages

```sh
pacman -S smartmontools xdg-utils i3-wm i3lock i3status i3blocks xss-lock alacritty wezterm pango lxappearance polybar rofi dunst feh flameshot gsimplecal yazi ueberzugpp network-manager-applet nm-connection-editor nitrogen thunar thunar-archive-plugin thunar-media-tags-plugin thunar-volman noto-fonts noto-fonts-emoji ttf-ubuntu-font-family ttf-roboto ttf-roboto-mono ttf-cascadia-mono-nerd ttf-font-awesome ttf-jetbrains-mono-nerd scrot imagemagick picom maim power-profiles-daemon polkit polkit-gnome arandr firefox hunspell hunspell-en_us hunspell-el seahorse gnome-keyring

systemctl enable lightdm.service
```

3. Install Sound

```sh
pacman -S pipewire pipewire-alsa pipewire-jack pipewire-pulse gst-plugin-pipewire libpulse wireplumber sof-firmware pavucontrol easyeffects
# Do not forget to enable the user services: pipewire-pulse.service and pipewire-pulse.socket
sudo su - ioangel
mkdir -p ~/.config/systemd/user/default.target.wants
ln -sf /usr/lib/systemd/user/pipewire-pulse.service /home/ioangel/.config/systemd/user/default.target.wants/pipewire-pulse.service
ln -sf /usr/lib/systemd/user/pipewire-pulse.socket /home/ioangel/.config/systemd/user/default.target.wants/pipewire-pulse.socket
```

4. Install `Docker`

```sh
pacman -S docker docker-buildx pigz
systemctl enable docker
usermod -a -G docker ioangel
# pigz: Parallel implementation of the gzip file compressor (optinal dep)
```

5. Install Bluetooth and Wireless

```sh
pacman -S iwd wireless_tools wpa_supplicant bluez bluez-utils blueman
systemctl enable bluetooth
# maybe need to enable 'iwd' for wireless?
```

6. Install Printer support

```sh
pacman -S cups cups-filters cups-pdf system-config-printer hplip
systemctl enable cups.service
```

7. Install Virtualization

```sh
pacman -S virtualbox virtualbox-host-dkms virtualbox-guest-iso gnome-boxes
usermod -a -G vboxusers ioangel
```

8. Choose fastest pacman mirrors

```sh
reflector --country Greece,Germany \
 --fastest 10 \
    --threads $(nproc) \
    --save /etc/pacman.d/mirrorlist

systemctl enable reflector.timer
```

## Setup Booting

1. Edit the `mkinitcpio` file for encrypt:

- `nvim /etc/mkinitcpio.conf` and search for HOOKS;
- add `encrypt` (before filesystems hook);
- add `atkbd` to the MODULES (enables external keyboard at device decryption prompt);
- add `btrfs` to the MODULES and,
- recreate the `mkinitcpio -p linux`

2. Setup `grub`

- Run: `grub-install --target=x86_64-efi --efi-directory=/efi --boot-directory=/boot --bootloader-id=arch`
- Run: `grub-mkconfig -o /boot/grub/grub.cfg`
- run blkid and obtain the UUID for the main partition: `blkid /dev/vda2` (check the partition name)
- edit the grub config `nvim /etc/default/grub`:
  - `GRUB_CMDLINE_LINUX_DEFAULT="loglevel=3 quiet cryptdevice=UUID=b47e666c-fec3-45c5-a2ed-bdb0abe25ac0:main root=/dev/mapper/main"`
- make the grub config with `grub-mkconfig -o /boot/grub/grub.cfg`
