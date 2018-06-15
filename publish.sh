#!/usr/bin/env bash

_date="$(date +%s)"
_ver="${CIRCLE_SHA1}"
v="${_date}.${_ver}"

gzip -1 installercore.iso

curl -XPUT "https://artifactory.palantir.build/artifactory/internal-dist-sandbox/com/palantir/rbergeron/xenial-surrogate/${v}/xenial-surrogate-${v}.iso.gz" -T "installercore.iso.gz"
