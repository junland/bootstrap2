#!/bin/true
set -e

. $(dirname $(realpath -s $0))/common.sh

extractSource diffutils

printInfo "Configuring diffutils"
serpentChrootCd diffutils*
serpentChroot ./configure \
    --host="${SERPENT_TRIPLET}" \
    --build="${SERPENT_TRIPLET}" \
    --prefix=/usr \
    --sysconfdir=/etc \
    --libdir=/usr/lib \
    --bindir=/usr/bin \
    --sbindir=/usr/sbin \
    --datadir=/usr/share

printInfo "Building diffutils"
serpentChroot make -j${SERPENT_BUILD_JOBS}
serpentChroot make -j${SERPENT_BUILD_JOBS} install
