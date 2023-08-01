#!/bin/bash

set -eu

if [[ $EUID -ne 0 ]]; then
  echo 'This script must be run as root.'
  exit 1
fi

arch_bootstrap_url="$MIRROR/iso/latest/archlinux-bootstrap-x86_64.tar.gz"

work=work
rm -fr "$work"
mkdir "$work"

curl "$arch_bootstrap_url" | tar -xzC "$work"
arch_bootstrap="$work/root.x86_64"
mount -B "$arch_bootstrap" "$arch_bootstrap"
trap 'umount "$arch_bootstrap"' EXIT

arch_chroot="$arch_bootstrap/bin/arch-chroot"

"$arch_chroot" "$arch_bootstrap" /bin/bash << EOF
pacman-key --init
pacman-key --populate
EOF

echo "Server = $MIRROR/\$repo/os/\$arch" >> "$arch_bootstrap/etc/pacman.d/mirrorlist"
git clone "$PROFILE" "$arch_bootstrap/archlive"

"$arch_chroot" "$arch_bootstrap" /bin/bash << EOF
pacman --noconfirm -Syu archiso
cd /archlive
mkarchiso -v .
EOF

out="$work/out"
ln -s root.x86_64/archlive/out "$out"
