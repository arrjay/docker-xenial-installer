#!/bin/sh

type unpack_archive > /dev/null 2>&1 || . /lib/img-lib.sh

unpack_archive /sysroot/var.tar.xz  /sysroot/var
unpack_archive /sysroot/tmp.tar.xz  /sysroot/tmp
unpack_archive /sysroot/ssh.tar.xz  /sysroot/etc/ssh
unpack_archive /sysroot/home.tar.xz /sysroot/home
