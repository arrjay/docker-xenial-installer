#!/usr/bin/env bash

set -ex

[ -z "${NOPUSH}" ] && docker pull "${DOCKER_SINK}/ubuntu-16.04-vm-bootable"
docker tag  "${DOCKER_SINK}/ubuntu-16.04-vm-bootable" "xenial-bootable"

set -u

cd docker && docker build -t "build/xenial-installer" .
