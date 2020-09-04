#!/usr/bin/env bash

# exit when any command fails
set -e

. /arch-env.sh
rm -f lukskey

ln -sf /usr/share/zoneinfo/Europe/Berlin /etc/localtime

# This should (in theory) sync the clock between Windows and Linux but it doesn't seem to work
# TODO: https://wiki.archlinux.org/index.php/System_time#Time_standard
# timedatectl set-local-rtc 1 --adjust-system-clock
# hwclock --systohc --localtime <-- Only run this if the previous command doesn't work (because e.g. timedatectl is not available)

echo "KEYMAP=de" > /etc/vconsole.conf

echo "$HOSTNAME" > /etc/hostname
echo "127.0.0.1 localhost" > /etc/hosts
echo "::1       localhost" >> /etc/hosts
echo "127.0.1.1 $HOSTNAME.localdomain $HOSTNAME" >> /etc/hosts

# Dracut might be the future but didn't boot when I tried it:
#export KVER=<Kernel version we just installed, see /lib/modules>
#dracut    /boot/EFI/arch/initramfs-linux.img          --kver $KVER --force
#dracut -N /boot/EFI/arch/initramfs-linux-fallback.img --kver $KVER --force
#cp /lib/modules/$KVER/vmlinuz /boot/EFI/arch/vmlinuz-linux

# Instead use mkinitcpio for now:
sed -i "s/^HOOKS=.*/HOOKS=(base udev autodetect modconf block filesystems keyboard encrypt)/g" /etc/mkinitcpio.conf
sed -i 's|^default_image=.*|default_image="/boot/EFI/arch/initramfs-linux.img"|g' /etc/mkinitcpio.d/linux.preset
sed -i 's|^fallback_image=.*|fallback_image="/boot/EFI/arch/initramfs-linux-fallback.img"|g' /etc/mkinitcpio.d/linux.preset

mkinitcpio -p linux

bootctl --path=/boot install

cat <<EOT >/boot/loader/loader.conf
default  arch.conf
timeout  3
editor   yes
EOT

# ext4: root=/dev/mapper/arch-root
# brtfs: root=/dev/mapper/cryptroot
cat <<EOT >/boot/loader/entries/arch.conf
title   Arch Linux
linux   /vmlinuz-linux
initrd  /EFI/arch/initramfs-linux.img
options cryptdevice=/dev/nvme0n1p6:cryptroot:allow-discards root=/dev/mapper/cryptroot rootflags=subvol=root quiet rw
EOT

systemctl enable iwd sshd systemd-networkd systemd-resolved

useradd -G wheel -s /bin/zsh -m -U $USER_NAME
echo "$USER_NAME:$USER_PASSWORD" | chpasswd

echo "%wheel ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/wheel

cat <<EOT >/etc/systemd/network/25-wireless.network
[Match]
Name=wlan0

[Network]
DHCP=yes

[DHCP]
RouteMetric=20
EOT
