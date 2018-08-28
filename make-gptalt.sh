#!/usr/bin/env bash

set -ex

docker run --rm=true -v $(pwd):/workdir:Z ${DOCKER_SINK}/xenial-surrogate

truncate -s3G boottest.img

# 2048 sectors to a megabyte
guestfish -a boottest.img << _EOF_
run
part-init /dev/sda gpt
part-add /dev/sda p 2048   10240
part-add /dev/sda p 12288  102400
#part-add /dev/sda p 104448 204800
part-add /dev/sda p 208440 -2048
part-set-gpt-type /dev/sda 1 21686148-6449-6E6F-744E-656564454649
part-set-gpt-type /dev/sda 2 C12A7328-F81F-11D2-BA4B-00A0C93EC93B
#part-set-gpt-type /dev/sda 3 EBD0A0A2-B9E5-4433-87C0-68B6B72699C7
part-set-gpt-type /dev/sda 3 0FC63DAF-8483-4772-8E79-3D69D8477DE4
_EOF_

guestfish -a boottest.img -a installercore.iso << _EOF_
run
copy-device-to-device /dev/sdb /dev/sda3
mount /dev/sda3 /
copy-file-to-device /boot/efiboot.img /dev/sda2
umount /
mount /dev/sda2 /
copy-in grub.cfg /efi/boot
_EOF_
