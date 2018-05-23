#!/bin/sh

depends() {
  echo "img-lib"
  return 0
}

install() {
  inst_hook cleanup 00 "$moddir/instantiate-fs.sh"
}
