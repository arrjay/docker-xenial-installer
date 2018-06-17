#!/usr/bin/env bash

set -eux

echo "tar may produce errors here as we told it to keep old files - we are ignoring it"
tar --extract --file="${1}" --keep-old-files --preserve-permissions -C /mnt/sysimage || true

mount -o bind /dev/ /mnt/sysimage/dev/
mount -o bind /proc/ /mnt/sysimage/proc/
mount -o bind /sys/ /mnt/sysimage/sys/

chroot /mnt/sysimage /bin/run-parts /scripts/grub-config
chroot /mnt/sysimage /bin/run-parts /scripts/dracut-config

: >   /mnt/sysimage/etc/machine-id
rm -f /mnt/sysimage/var/lib/dbus/machine-id

rm -f /mnt/sysimage/etc/resolv.conf
ln -s /run/resolvconf/resolv.conf /mnt/sysimage/etc/resolv.conf
