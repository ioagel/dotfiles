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
# Look at your disks, and adjust (vda is usual in libvirt, in bare metal the naming will be different)
# NAME  MAJ:MIN RM   SIZE RO TYPE MOUNTPOINTS
# loop0   7:0    0 846.7M  1 loop /run/archiso/airootfs
# sr0    11:0    1   1.2G  0 rom  /run/archiso/bootmnt
# vda   254:0    0    50G  0 disk

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
# vda    254:0    0    50G  0 disk
# ├─vda1 254:1    0     1G  0 part
# ├─vda2 254:1    0     1G  0 part
# └─vda3 254:2    0    48G  0 part
```

### Encrypt Main Partition

```sh
# Setup (choose a good rememberable password)
# cryptsetup luksFormat --type luks2 --cipher aes-xts-plain64 --pbkdf argon2id /dev/vda3
cryptsetup  luksFormat /dev/vda3
# Open
cryptsetup luksOpen /dev/vda3 cryptroot # 'cryptroot' or choose any other appropriate
# Format (using btrfs)
mkfs.btrfs /dev/mapper/cryptroot
```

### BTRFS Subvolume Setup

```sh
# Mount our main partition and cd to it
mount /dev/mapper/cryptroot /mnt
cd /mnt
# Create the subvolumes
btrfs su cr @
btrfs su cr @home
btrfs su cr @cache
btrfs su cr @tmp
btrfs su cr @log
btrfs su cr @images
btrfs su cr @docker
btrfs su cr @snapshots
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
mount -o noatime,ssd,compress=zstd,space_cache=v2,discard=async,subvol=@ /dev/mapper/cryptroot /mnt
# Created the needed mount points for the rest of the subvolumes
mkdir -p /mnt/{boot,efi,home,var/cache,var/tmp,var/log,var/lib/libvirt/images,var/lib/docker,.snapshots}

# Mount the subvolumes
mount -o noatime,ssd,compress=zstd,space_cache=v2,discard=async,subvol=@home /dev/mapper/cryptroot /mnt/home
mount -o noatime,ssd,compress=zstd,space_cache=v2,discard=async,subvol=@cache /dev/mapper/cryptroot /mnt/var/cache
mount -o noatime,ssd,compress=zstd,space_cache=v2,discard=async,subvol=@tmp /dev/mapper/cryptroot /mnt/var/tmp
mount -o noatime,ssd,compress=zstd,space_cache=v2,discard=async,subvol=@log /dev/mapper/cryptroot /mnt/var/log
mount -o noatime,ssd,compress=zstd,space_cache=v2,discard=async,subvol=@images /dev/mapper/cryptroot /mnt/var/lib/libvirt/images
mount -o noatime,ssd,compress=zstd,space_cache=v2,discard=async,subvol=@docker /dev/mapper/cryptroot /mnt/var/lib/docker
mount -o noatime,ssd,compress=zstd,space_cache=v2,discard=async,subvol=@snapshots /dev/mapper/cryptroot /mnt/.snapshots

# Set the proper permissions for '/var/tmp'
chmod 1777 /mnt/var/tmp

# Format EFI
mkfs.fat -F32 /dev/vda1 
# Mount the EFI partition 
mount /dev/vda1 /mnt/efi
# Format and mount Boot
mkfs.ext4 /dev/vda2
mount /dev/vda2 /mnt/boot
```

## Basic System Install

1. Syncronise the Package Database

```sh
pacman -Syy
```

2. Setup `reflector` for fast mirrors:

```sh
# Greece causes me problems
reflector --verbose --protocol https --latest 10 --sort rate --country 'Greece,Germany,Italy' --save /etc/pacman.d/mirrorlist
```

3. Install essential packages into new filesystem and generate fstab:

```sh
pacstrap /mnt base base-devel linux linux-headers linux-lts linux-lts-headers \
    linux-firmware $MICROCODE btrfs-progs grub efibootmgr neovim networkmanager gvfs \
    exfatprogs dosfstools e2fsprogs man-db man-pages texinfo openssh git reflector \
    wget cryptsetup wpa_supplicant terminus-font sudo iptables-nft mkinitcpio ansible \
    rsync python-passlib
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

# nvim /etc/locale.gen # uncomment your locales, i.e. `en_US.UTF-8` and `el_GR.UTF-8`
export locale="en_US.UTF-8"
export locale2="el_GR.UTF-8"
sed -i "s/^#\(${locale}\)/\1/" /etc/locale.gen
sed -i "s/^#\(${locale2}\)/\1/" /etc/locale.gen
locale-gen
echo "LANG=${locale}" > /etc/locale.conf
```

3. Setup system hostname:

```sh
echo "yourhostname" > /etc/hostname
echo -e "127.0.1.1  yourhostname.localdomain  yourhostname" >> /etc/hosts
# nvim /etc/hosts
# 127.0.0.1 localhost
# ::1       localhost
# 127.0.1.1 yourhostname
```

4. Set keyboard layout and terminal font

```sh
echo "KEYMAP=us" >> /etc/vconsole.conf
echo "FONT=ter-v20n" >> /etc/vconsole.conf
echo "KEYMAP_TOGGLE=gr" >> /etc/vconsole.conf
```

5. Set default editor

```sh
echo "EDITOR=nvim" >> /etc/environment
echo "VISUAL=nvim" >> /etc/environment
```

6. Add new users and setup passwords:

```sh
# Main user
useradd -m -G wheel,storage,power,audio,video -s /bin/bash -c "Your name" ioangel
# remote_admin user needed to manage machine from remote hosts
useradd -m -s /bin/bash remote_admin
passwd root
passwd ioangel
# Do not add passwd for remote_admin, can login only through ssh keys

# Add names to created users
#nvim /etc/passwd
# ioangel:x:1000:1000:Ioannis Angelakopoulos:/home/ioangel:/bin/bash        remote_admin:x:1001:1001:Remote Admin:/home/remote_admin:/bin/bash
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
pacman -S base-devel grub btrfs-progs grub-btrfs efibootmgr exfatprogs ntfs-3g openssh git reflector amd-ucode bash-completion man-db man-pages plocate iptables-nft zip unzip htop btop tree wget rsync bind lshw openvpn wireguard-tools stow tldr jq zellij step-cli eza borg networkmanager networkmanager-openvpn
# lshw: Provides detailed information on the hardware of the machine
# bind: I use dig utility for DNS resolution from this package

systemctl enable NetworkManager
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

## Setup Booting (everything encrypted including /boot with grub, only passphrase support)

1. Edit the `mkinitcpio` file for encrypt:

- `nvim /etc/mkinitcpio.conf` and search for HOOKS;
- add `encrypt` (before filesystems hook);
- add `atkbd` to the MODULES (enables external keyboard at device decryption prompt) - OPTIONAL;
- add `btrfs` to the MODULES and,
- recreate the `mkinitcpio -P`

2. Setup `grub`

- Run: `grub-install --target=x86_64-efi --efi-directory=/efi --boot-directory=/boot --bootloader-id=arch`
- Run: `grub-mkconfig -o /boot/grub/grub.cfg`
- run blkid and obtain the UUID for the main partition: `blkid /dev/vda2` (check the partition name)
- edit the grub config `nvim /etc/default/grub`:
  - `GRUB_CMDLINE_LINUX_DEFAULT="loglevel=3 quiet cryptdevice=UUID=b47e666c-fec3-45c5-a2ed-bdb0abe25ac0:main root=/dev/mapper/main"`
  - uncomment `GRUB_ENABLE_CRYPTODISK=y`
- make the grub config with `grub-mkconfig -o /boot/grub/grub.cfg`

## Setup Booting with /boot unencrypted including grub, including keyfile (EFI and /boot in external USB)

- Create the crypto keyfile

```sh
cd /efi
dd bs=512 count=4 if=/dev/random of=crypto_keyfile.bin iflag=fullblock
cryptsetup luksAddKey /dev/vda3 /efi/crypto_keyfile.bin
# enter your encryption password when prompted
# cryptsetup luksDump /dev/vda3
# You should now see that LUKS Key Slots 0 and 1 are both occupied
```

- Edit `/etc/mkinitcpio.conf`

```conf
MODULES=(btrfs crc32c)
FILES=(/efi/crypto_keyfile.bin)
HOOKS=(base udev autodetect microcode modconf kms keyboard keymap consolefont block **encrypt** filesystems fsck)
```

run: `mkinitcpio -P`

- Setup `grub`

- Run: `grub-install --target=x86_64-efi --efi-directory=/efi --removable --bootloader-id=GRUB`
- run blkid and obtain the UUID for the main partition: `blkid /dev/vda3` (check the partition name)
- edit the grub config `nvim /etc/default/grub`:
  - `GRUB_CMDLINE_LINUX_DEFAULT="loglevel=3 quiet cryptdevice=UUID=b47e666c-fec3-45c5-a2ed-bdb0abe25ac0:cryptroot root=/dev/mapper/cryptroot cryptkey=rootfs:/efi/crypto_keyfile.bin"`
- make the grub config with `grub-mkconfig -o /boot/grub/grub.cfg`
