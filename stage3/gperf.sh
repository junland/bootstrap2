#!/bin/true
set -e

. $(dirname $(realpath -s $0))/common.sh

extractSource gperf
serpentChrootCd gperf-*


printInfo "Configuring gperf"

serpentChroot ./configure \
    --build="${SERPENT_TRIPLET}" \
    --host="${SERPENT_TRIPLET}" \
    --prefix=/usr \
    --sysconfdir=/etc \
    --libdir=/usr/lib \
    --bindir=/usr/bin \
    --sbindir=/usr/sbin \
    --datadir=/usr/share \


printInfo "Building gperf"
serpentChroot make -j "${SERPENT_BUILD_JOBS}"

printInfo "Installing gperf"
serpentChroot make -j "${SERPENT_BUILD_JOBS}" install
