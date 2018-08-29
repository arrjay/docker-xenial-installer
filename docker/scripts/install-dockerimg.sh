#!/bin/bash

HOST=docker.io
IMAGE=redjays/xenial-bootable
TAG=latest
DIRECTORY=/mnt/sysimage
QUIET="false"

OPTIND=1
while getopts d:h:i:t:q _opt ; do
  case ${_opt} in
    d)
      DIRECTORY="${OPTARG}"
      ;;
    h)
      HOST="${OPTARG}"
      ;;
    i)
      IMAGE="${OPTARG}"
      ;;
    t)
      TAG="${OPTARG}"
      ;;
    q)
      QUIET="true"
      ;;
  esac
done

set -e

if [ "${QUIET}" == "false" ] ; then
  # attempt to determine tty or pipe
  if [ -t 0 ] ; then
    curl_layer_flags="-#"
  else
    curl_layer_flags="-sS"
  fi
else
  curl_layer_flags="-sS"
fi

echo "retriving manifest https://${HOST}/v2/${IMAGE}/manifests/${TAG}"
for l in $(curl -sS -u 'anonymous:' "https://${HOST}/v2/${IMAGE}/manifests/${TAG}" | jq ."fsLayers"[].blobSum|sed -e s/\"//g|tac) ; do
  echo "retrieving layer ${l}"
  mkdir -p "${DIRECTORY}/tmp/${l}"
  curl "${curl_layer_flags}" -u 'anonymous:' "https://${HOST}/v2/${IMAGE}/blobs/$l" | tar xpz --numeric-owner -C "${DIRECTORY}/tmp/${l}"
  find "${DIRECTORY}/tmp/${l}" -name .wh.\* | while read -r path; do
    echo "recreating ${path}"
    rm "$path" && touch "$path"
  done
  rsync -aH "${DIRECTORY}/tmp/${l}/" "${DIRECTORY}/"
  rm -rf "${DIRECTORY}/tmp/${l}"
  find "${DIRECTORY}" -name .wh.\* | while read -r path; do
    basename="${path##*/}"
    dirname="${path%${basename}}"
    basename="${basename#.wh.}"
    echo "whiteout file in layer - removing ${dirname}${basename}"
    rm -rf "$path" "${dirname}${basename}"
  done
done

mkdir -p /mnt/sysimage/run/platform-info

rsync -av /tmp/overlay/ /mnt/sysimage/

mount -o bind /dev/ /mnt/sysimage/dev/
mount -o bind /proc/ /mnt/sysimage/proc/
mount -o bind /sys/ /mnt/sysimage/sys/
mount -o bind /run/platform-info /mnt/sysimage/run/platform-info

[ -x /mnt/sysimage/bin/run-parts ]     && run_parts="/bin/run-parts"
[ -x /mnt/sysimage/usr/bin/run-parts ] && run_parts="/usr/bin/run-parts"

[ ! -z "${run_parts:-}" ] || { echo "cannot find run-parts in sysimage (bad unpack?)" 2>&1 ; exit 2 ; }

for d in /scripts/dracut-config /scripts/grub-config /scripts/final-config ; do
  if [ -d "/mnt/sysimage/$d" ] ; then
    chroot /mnt/sysimage "$run_parts" "$d"
  fi
done

#chroot /mnt/sysimage passwd root
