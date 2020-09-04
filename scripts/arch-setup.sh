#!/usr/bin/env bash

# exit when any command fails
set -e

# Sync package information
pacman -Sy

timedatectl set-ntp true

cryptsetup -c aes-xts-plain64 -y --use-random --batch-mode luksFormat /dev/nvme0n1p6 < lukskey
cryptsetup luksOpen /dev/nvme0n1p6 cryptroot - < lukskey

# Option 1: LVM + EXT4
# We'll only create a single logical volume and no swap partition because we'll use a swap file instead
# https://wiki.archlinux.org/index.php/Swap#Swap_file
#pvcreate /dev/mapper/cryptroot
#vgcreate arch /dev/mapper/cryptroot
#lvcreate -l +100%FREE arch -n root

#mkfs.ext4 -F /dev/mapper/arch-root
#mount /dev/mapper/arch-root /mnt

#mkdir /mnt/boot
#mount /dev/nvme0n1p1 /mnt/boot
#rm -rf /mnt/boot/EFI/arch
#mkdir /mnt/boot/EFI/arch


# Option 2: BTRFS
mkfs.btrfs -L arch /dev/mapper/cryptroot
mount /dev/mapper/cryptroot /mnt

btrfs subvolume create /mnt/root
btrfs subvolume create /mnt/home
btrfs subvolume create /mnt/swap
btrfs subvolume create /mnt/root/.snapshots
btrfs subvolume create /mnt/home/.snapshots

umount /mnt
mount -o noatime,subvol=root,compress=zstd /dev/mapper/cryptroot /mnt

mkdir /mnt/boot
mount /dev/nvme0n1p1 /mnt/boot
rm -rf /mnt/boot/EFI/arch
mkdir /mnt/boot/EFI/arch

mkdir /mnt/home
mount -o noatime,subvol=home,compress=zstd /dev/mapper/cryptroot /mnt/home

mkdir -p /mnt/var/swap
mount -o noatime,subvol=swap /dev/mapper/cryptroot /mnt/var/swap

pacman -S --noconfirm pacman-contrib
curl -s "https://www.archlinux.org/mirrorlist/?country=DE&country=DK&protocol=https&use_mirror_status=on" | sed -e 's/^#Server/Server/' -e '/^#/d' | rankmirrors - -n 20 > /etc/pacman.d/mirrorlist

rm -f /mnt/boot/intel-ucode.img

# Go is needed for chezmoi
# ext4: lvm2 needs to be added
pacstrap /mnt ansible base base-devel dhcpcd git go intel-ucode iwd linux linux-firmware openssh rsync sudo vim zsh

# Check and edit if it's wrong!
genfstab -U /mnt >> /mnt/etc/fstab
sed -i -E 's|(\S+\s+/\s+btrfs\s+)(\S*)(.*)|\1rw,noatime,compress=zstd:3,ssd,space_cache,subvol=root\3|g' /mnt/etc/fstab
sed -i -E 's|(\S+\s+/home\s+btrfs\s+)(\S*)(.*)|\1rw,noatime,compress=zstd:3,ssd,space_cache,subvol=home\3|g' /mnt/etc/fstab
sed -i -E 's|(\S+\s+/var/swap\s+btrfs\s+)(\S*)(.*)|\1rw,noatime,compress=zstd:3,ssd,space_cache,subvol=swap\3|g' /mnt/etc/fstab

cp arch-setup-chroot.sh /mnt/
cp arch-env.sh /mnt
arch-chroot /mnt /arch-setup-chroot.sh
rm -f /mnt/arch-setup-chroot.sh
rm -f /mnt/arch-env.sh

cp -R /var/lib/iwd /mnt/var/lib

umount -R /mnt
reboot

# TODO:
# - https://gist.github.com/eltonvs/d8977de93466552a3448d9822e265e38
# - https://medium.com/@mudrii/arch-linux-installation-on-hw-with-i3-windows-manager-part-1-5ef9751a0be https://turlucode.com/arch-linux-install-guide-efi-lvm-luks/#1499978674598-08215a45-7f6a
