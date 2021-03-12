#!/bin/true
set -e

. $(dirname $(realpath -s $0))/common.sh

extractSource findutils
serpentChrootCd findutils-*

printInfo "Configuring findutils"
serpentChroot ./configure \
    --prefix=/usr \
    --sysconfdir=/etc \
    --libdir=/usr/lib \
    --bindir=/usr/bin \
    --sbindir=/usr/sbin \
    --datadir=/usr/share \
    --build="${SERPENT_TRIPLET}" \
    --host="${SERPENT_TRIPLET}"

printInfo "Building findutils"
serpentChroot make -j "${SERPENT_BUILD_JOBS}"
serpentChroot make -j "${SERPENT_BUILD_JOBS}" install
