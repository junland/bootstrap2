#!/bin/true
set -e

. $(dirname $(realpath -s $0))/common.sh

extractSource xz
serpentChrootCd xz-*


printInfo "Configuring xz"
# Enable largefile support
export CFLAGS="${CFLAGS} -D_FILE_OFFSET_BITS=64"
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


printInfo "Building xz"
serpentChroot make -j "${SERPENT_BUILD_JOBS}"

printInfo "Installing xz"
serpentChroot make -j "${SERPENT_BUILD_JOBS}" install
