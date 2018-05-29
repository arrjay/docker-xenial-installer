#!/usr/bin/env bash

set -eux

[ -d /workdir ] || {
  echo "script requires /workdir volume mount for saving contents" 1>&2
  exit 1
}

xorriso_image_graft="-graft-points /images=/images"
[ -d /workdir/images ] && {
  xorriso_image_graft="-graft-points /images=/workdir/images"
}

xorriso --report_about HINT -as xorrisofs -U -A xe_installer -V xe_installer -volset xe_installer -r -rational-rock -o /tmp/installercore.iso \
  -graft-points "/isolinux=/isolinux" \
  -graft-points "/EFI=/EFI" -graft-points "/bin=/bin" -graft-points "/boot=/boot" -graft-points "/etc=/etc" \
  -graft-points "/lib=/lib" -graft-points "/lib64=/lib64" -graft-points "/media=/media" -graft-points "/mnt=/mnt" \
  -graft-points "/opt=/opt" -graft-points "/root=/root" -graft-points "/sbin=/sbin" -graft-points "/scripts=/scripts" \
  -graft-points "/srv=/srv" -graft-points "/usr=/usr" \
  -graft-points "/etc=/cdroot/etc" \
  ${xorriso_image_graft} \
  -partition_cyl_align off -partition_offset 0 -apm-block-size 2048 \
  -b isolinux/isolinux.bin -c boot/boot.cat -no-emul-boot -boot-load-size 4 -boot-info-table \
  -isohybrid-mbr "/isolinux/isohdpfx.bin" --protective-msdos-label \
  -eltorito-alt-boot -e /boot/efiboot.img -no-emul-boot -isohybrid-gpt-basdat \
  -eltorito-alt-boot -e /boot/macboot.img -no-emul-boot -isohybrid-gpt-basdat -isohybrid-apm-hfsplus \
  "/cdroot" -- \
  -zisofs level=9:block_size=128k set_filter_r --zisofs /bin /etc /lib /opt /root /sbin /scripts /usr -- \
  -chmodi u+s /usr/bin/sudo --

isohybrid /tmp/installercore.iso

mv /tmp/installercore.iso /workdir
