#!/usr/bin/env bash

set -ex

docker run --name newfs build/xenial-installer true

scratch=$(mktemp -d /var/tmp/newfs.XXXXXX)
isolinux=$(mktemp -d /var/tmp/isolinux.XXXXXX)

cp /usr/share/syslinux/*.c32 /usr/share/syslinux/isolinux.bin /usr/share/syslinux/isohd*.bin "${isolinux}"

docker export newfs | tar xf - -C "${scratch}" '--exclude=dev/*' '--exclude=var/*' '--exclude=tmp/*' '--exclude=etc/ssh/*' \
  '--exclude=home/*' \
  '--exclude=usr/lib/locale' '--exclude=usr/share/locale' '--exclude=lib/gconv' '--exclude=lib64/gconv' \
  '--exclude=bin/localedef'  '--exclude=sbin/build-locale-archive' '--exclude=usr/share/i18n' \
  '--exclude=usr/share/man'  '--exclude=usr/share/doc' '--exclude=usr/share/info' '--exclude=usr/share/gnome/help' \
  '--exclude=usr/share/cracklib' '--exclude=var/cache/yum' '--exclude=sbin/sln' '--exclude=var/cache/ldconfig' \
  '--exclude=var/cache/apt/archives' '--exclude=var/lib/apt/lists'

docker rm newfs

pxz "${scratch}/var.tar"
pxz "${scratch}/tmp.tar"
pxz "${scratch}/ssh.tar"
pxz "${scratch}/home.tar"

ln -sf "../proc/self/mounts" "${scratch}/etc/mtab"

cp -R "${scratch}/boot" "${isolinux}/boot"

cat << _EOF_ > "${isolinux}/syslinux.cfg"
serial 1 115200
timeout 900
prompt 1
_EOF_

cat "${scratch}/isolinux/syslinux.cfg.tpl"

sed -e 's/console=tty0/console=ttyS1,115200/g' \
    -e 's/root=UNSET/root=LABEL=xe_installer/g' \
      "${scratch}/isolinux/syslinux.cfg.tpl" >> "${isolinux}/syslinux.cfg"

sed -e 's/console=tty0/console=ttyS1,115200/g' \
    -e 's/root=UNSET/root=LABEL=xe_installer/g' \
      "${scratch}/boot/grub/grub.cfg.tpl" >> "${scratch}/boot/grub/grub.cfg"

for k in "${isolinux}/boot"/vmlinuz* "${isolinux}/boot"/initrd.img* ; do
  d="${k##*/}"
  ln "${k}" "${isolinux}/${d}"
done

xorriso --report_about HINT -as xorrisofs -U -A xe_installer -V xe_installer -volset xe_installer -r -rational-rock -o installercore.iso \
  -graft-points "/isolinux=${isolinux}" \
  -partition_cyl_align off -partition_offset 0 -apm-block-size 2048 -iso_mbr_part_type 0x00 \
  -b isolinux/isolinux.bin -c boot/boot.cat -no-emul-boot -boot-load-size 4 -boot-info-table \
  -isohybrid-mbr "${scratch}/isolinux/isohdpfx.bin" --protective-msdos-label "${scratch}" \
  -eltorito-alt-boot -e /boot/efiboot.img -no-emul-boot -isohybrid-gpt-basdat \
  -eltorito-alt-boot -e /boot/macboot.img -no-emul-boot -isohybrid-gpt-basdat -isohybrid-apm-hfsplus -- \
  -chmodi u+s /usr/bin/sudo -- \

#  -find / -not -path /isolinux -exec set_filter --zisofs

isohybrid installercore.iso

rm -rf "${scratch}" "${isolinux}"
