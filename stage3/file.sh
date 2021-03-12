#!/bin/true
set -e

. $(dirname $(realpath -s $0))/common.sh

extractSource file
serpentChrootCd file-*


printInfo "Configuring file"

serpentChroot ./configure \
    --build="${SERPENT_TRIPLET}" \
    --host="${SERPENT_TRIPLET}" \
    --prefix=/usr \
    --sysconfdir=/etc \
    --libdir=/usr/lib \
    --bindir=/usr/bin \
    --sbindir=/usr/sbin \
    --datadir=/usr/share \
    --enable-shared \
    --disable-static


printInfo "Building file"
serpentChroot make -j "${SERPENT_BUILD_JOBS}"

printInfo "Installing file"
serpentChroot make -j "${SERPENT_BUILD_JOBS}" install
