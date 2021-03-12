#!/bin/true
set -e

. $(dirname $(realpath -s $0))/common.sh

extractSource attr
serpentChrootCd attr-*

printInfo "Configuring attr"
serpentChroot ./configure \
    --prefix=/usr \
    --sysconfdir=/etc \
    --libdir=/usr/lib \
    --bindir=/usr/bin \
    --sbindir=/usr/sbin \
    --datadir=/usr/share \
    --build="${SERPENT_TRIPLET}" \
    --host="${SERPENT_TRIPLET}" \
    --enable-shared \
    --disable-static

printInfo "Building attr"
serpentChroot make -j "${SERPENT_BUILD_JOBS}"
serpentChroot make -j "${SERPENT_BUILD_JOBS}" install
