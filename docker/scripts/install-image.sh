#!/usr/bin/env bash

set -eux

echo "tar may produce errors here as we told it to keep old files - we are ignoring it"
tar --extract --file="${1}" --keep-old-files --preserve-permissions --sparse -C /mnt/sysimage || true

mount -o bind /dev/ /mnt/sysimage/dev/
mount -o bind /proc/ /mnt/sysimage/proc/
mount -o bind /sys/ /mnt/sysimage/sys/

chroot /mnt/sysimage /bin/run-parts /scripts/grub-config
chroot /mnt/sysimage /bin/run-parts /scripts/dracut-config
chroot /mnt/sysimage passwd root
chroot /mnt/sysimage /bin/run-parts /scripts/final-config
