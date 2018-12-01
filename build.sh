#!/bin/bash

set -euo pipefail

arch="$1"

cp Dockerfile Dockerfile.$arch

case "$arch" in
    i386 ) base_image="resin/i386-alpine" ;;
    arm ) base_image="resin/rpi-alpine" ;;
    aarch64 ) base_image="resin/aarch64-alpine" ;;
esac

if [ -n "${base_image-}" ]; then
    sed -i "s@alpine:\\([0-9]\\+\\).\\([0-9]\\+\\)@$base_image@g" "Dockerfile.$arch"
fi
