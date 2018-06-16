#!/usr/bin/env bash

set -ex

docker run --name newfs --entrypoint true build/xenial-installer

scratch=$(mktemp -d /var/tmp/newfs.XXXXXX)
isolinux=$(mktemp -d /var/tmp/isolinux.XXXXXX)

yum -y install syslinux xorriso rsync

docker export newfs | tar xf - -C "${scratch}" '--exclude=dev/*' '--exclude=var/*' '--exclude=tmp/*' '--exclude=etc/ssh/*' \
  '--exclude=home/*' \
  '--exclude=usr/lib/locale' '--exclude=usr/share/locale' '--exclude=lib/gconv' '--exclude=lib64/gconv' \
  '--exclude=bin/localedef'  '--exclude=sbin/build-locale-archive' '--exclude=usr/share/i18n' \
  '--exclude=usr/share/man'  '--exclude=usr/share/doc' '--exclude=usr/share/info' '--exclude=usr/share/gnome/help' \
  '--exclude=usr/share/cracklib' '--exclude=var/cache/yum' '--exclude=sbin/sln' '--exclude=var/cache/ldconfig' \
  '--exclude=var/cache/apt/archives' '--exclude=var/lib/apt/lists'

docker rm newfs

rsync -R "${scratch}/isolinux/" "${isolinux}/"

cp /usr/share/syslinux/*.c32 /usr/share/syslinux/isolinux.bin /usr/share/syslinux/isohd*.bin "${isolinux}"

xorriso_image_graft="-graft-points /images=${scratch}/images"
if [ -d "$(pwd)/images" ] ; then
  xorriso_image_graft="-graft-points /images=$(pwd)/images"
fi

xorriso --report_about HINT -as xorrisofs -U -A xe_installer -V xe_installer -volset xe_installer -r -rational-rock -o installercore.iso \
  -graft-points "/isolinux=${isolinux}" \
  -graft-points "/EFI=${scratch}/EFI" -graft-points "/bin=${scratch}/bin" -graft-points "/boot=${scratch}/boot" -graft-points "/etc=${scratch}/etc" \
  -graft-points "/lib=${scratch}/lib" -graft-points "/lib64=${scratch}/lib64" -graft-points "/media=${scratch}/media" -graft-points "/mnt=${scratch}/mnt" \
  -graft-points "/opt=${scratch}/opt" -graft-points "/root=${scratch}/root" -graft-points "/sbin=${scratch}/sbin" -graft-points "/scripts=${scratch}/scripts" \
  -graft-points "/srv=${scratch}/srv" -graft-points "/usr=${scratch}/usr" \
  -graft-points "/etc=${scratch}/cdroot/etc" \
  ${xorriso_image_graft} \
  -partition_cyl_align off -partition_offset 0 -apm-block-size 2048 -iso_mbr_part_type 0x00 \
  -b isolinux/isolinux.bin -c boot/boot.cat -no-emul-boot -boot-load-size 4 -boot-info-table \
  -isohybrid-mbr "${scratch}/isolinux/isohdpfx.bin" --protective-msdos-label \
  -eltorito-alt-boot -e /boot/efiboot.img -no-emul-boot -isohybrid-gpt-basdat \
  -eltorito-alt-boot -e /boot/macboot.img -no-emul-boot -isohybrid-gpt-basdat -isohybrid-apm-hfsplus \
  "${scratch}/cdroot" -- \
  -zisofs level=9:block_size=128k set_filter_r --zisofs /bin /etc /lib /opt /root /sbin /scripts /usr -- \
  -chmodi u+s /usr/bin/sudo --

isohybrid installercore.iso

rm -rf "${scratch}" "${isolinux}"
