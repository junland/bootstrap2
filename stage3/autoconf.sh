#!/bin/true
set -e

. $(dirname $(realpath -s $0))/common.sh

extractSource autoconf
serpentChrootCd autoconf-*


printInfo "Configuring autoconf"

serpentChroot ./configure \
    --prefix=/usr \
    --sysconfdir=/etc \
    --libdir=/usr/lib \
    --bindir=/usr/bin \
    --sbindir=/usr/sbin \
    --datadir=/usr/share \


printInfo "Building autoconf"
serpentChroot make -j "${SERPENT_BUILD_JOBS}"

printInfo "Installing autoconf"
serpentChroot make -j "${SERPENT_BUILD_JOBS}" install
