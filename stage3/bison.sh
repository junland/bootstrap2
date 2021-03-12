#!/bin/true
set -e

. $(dirname $(realpath -s $0))/common.sh

extractSource bison
serpentChrootCd bison-*


printInfo "Configuring bison"

serpentChroot ./configure \
    --build="${SERPENT_TRIPLET}" \
    --host="${SERPENT_TRIPLET}" \
    --prefix=/usr \
    --sysconfdir=/etc \
    --libdir=/usr/lib \
    --bindir=/usr/bin \
    --sbindir=/usr/sbin \
    --datadir=/usr/share \


printInfo "Building bison"
serpentChroot make -j "${SERPENT_BUILD_JOBS}"

printInfo "Installing bison"
serpentChroot make -j "${SERPENT_BUILD_JOBS}" install
