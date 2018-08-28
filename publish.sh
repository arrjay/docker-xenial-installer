#!/usr/bin/env bash

_date="$(date +%s)"
_ver="${CIRCLE_SHA1}"
v="${_date}.${_ver}"

docker tag build/xenial-installer "${DOCKER_SINK}/xenial-surrogate"
docker tag build/xenial-installer "${DOCKER_SINK}/xenial-surrogate:latest.${_date}"

if [ -z "${NOPUSH}" ] ; then
  gzip -1 installercore.iso

  curl -XPUT "https://artifactory.palantir.build/artifactory/internal-dist-sandbox/com/palantir/rbergeron/xenial-surrogate/${v}/xenial-surrogate-${v}.iso.gz" -T "installercore.iso.gz"
fi
