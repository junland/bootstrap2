#!/bin/true
set -e

. $(dirname $(realpath -s $0))/common.sh

extractSource make
serpentChrootCd make-*


printInfo "Configuring make"

serpentChroot ./configure \
    --build="${SERPENT_TRIPLET}" \
    --host="${SERPENT_TRIPLET}" \
    --prefix=/usr \
    --sysconfdir=/etc \
    --libdir=/usr/lib \
    --bindir=/usr/bin \
    --sbindir=/usr/sbin \
    --datadir=/usr/share \


printInfo "Building make"
serpentChroot make -j "${SERPENT_BUILD_JOBS}"

printInfo "Installing make"
serpentChroot make -j "${SERPENT_BUILD_JOBS}" install
