#!/bin/true
set -e

. $(dirname $(realpath -s $0))/common.sh

extractSource libxml2
serpentChrootCd libxml2-*

export LDFLAGS="${LDFLAGS} -Wl,--allow-shlib-undefined"

printInfo "Configuring libxml2"
serpentChroot ./configure \
    --build="${SERPENT_TRIPLET}" \
    --host="${SERPENT_TRIPLET}" \
    --prefix=/usr \
    --sysconfdir=/etc \
    --libdir=/usr/lib \
    --bindir=/usr/bin \
    --sbindir=/usr/sbin \
    --datadir=/usr/share \


printInfo "Building libxml2"
serpentChroot make -j "${SERPENT_BUILD_JOBS}"

printInfo "Installing libxml2"
serpentChroot make -j "${SERPENT_BUILD_JOBS}" install
