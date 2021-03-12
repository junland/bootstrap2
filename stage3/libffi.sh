#!/bin/true
set -e

. $(dirname $(realpath -s $0))/common.sh

extractSource libffi
serpentChrootCd libffi-*


printInfo "Configuring libffi"

serpentChroot ./configure \
    --build="${SERPENT_TRIPLET}" \
    --host="${SERPENT_TRIPLET}" \
    --prefix=/usr \
    --sysconfdir=/etc \
    --libdir=/usr/lib \
    --bindir=/usr/bin \
    --sbindir=/usr/sbin \
    --datadir=/usr/share \


printInfo "Building libffi"
serpentChroot make -j "${SERPENT_BUILD_JOBS}"

printInfo "Installing libffi"
serpentChroot make -j "${SERPENT_BUILD_JOBS}" install
