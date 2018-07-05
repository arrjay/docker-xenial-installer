#!/usr/bin/env bash

set -ex

[ -z "${NOPUSH}" ] && docker pull "${DOCKER_SINK}/xenial-bootable"
docker tag  "${DOCKER_SINK}/xenial-bootable" "xenial-bootable"

set -u

cd docker && docker build -t "build/xenial-installer" .
