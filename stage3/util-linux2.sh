#!/bin/true
set -e

. $(dirname $(realpath -s $0))/common.sh

extractSource util-linux
serpentChrootCd util-linux-*


printInfo "Configuring util-linux"

serpentChroot ./configure \
    --prefix=/usr \
    --sysconfdir=/etc \
    --libdir=/usr/lib \
    --bindir=/usr/bin \
    --sbindir=/usr/sbin \
    --datadir=/usr/share \
    --build="${SERPENT_TRIPLET}" \
    --host="${SERPENT_TRIPLET}" \
    --disable-makeinstall-chown \
    --disable-makeinstall-setuid \


printInfo "Building util-linux"
serpentChroot make -j "${SERPENT_BUILD_JOBS}"

printInfo "Installing util-linux"
serpentChroot make -j "${SERPENT_BUILD_JOBS}" install
