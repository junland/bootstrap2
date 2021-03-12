#!/bin/true
set -e

. $(dirname $(realpath -s $0))/common.sh

extractSource python
serpentChrootCd Python-*


printInfo "Configuring python"

serpentChroot ./configure \
    --build="${SERPENT_TRIPLET}" \
    --host="${SERPENT_TRIPLET}" \
    --prefix=/usr \
    --sysconfdir=/etc \
    --libdir=/usr/lib \
    --bindir=/usr/bin \
    --sbindir=/usr/sbin \
    --datadir=/usr/share \
    --without-cxx-main \
    --disable-ipv6


printInfo "Building python"
serpentChroot make -j "${SERPENT_BUILD_JOBS}"

printInfo "Installing python"
serpentChroot make -j "${SERPENT_BUILD_JOBS}" install
