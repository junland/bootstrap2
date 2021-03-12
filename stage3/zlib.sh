#!/bin/true
set -e

. $(dirname $(realpath -s $0))/common.sh

extractSource zlib
serpentChrootCd zlib-*


printInfo "Configuring zlib"

serpentChroot ./configure --prefix=/usr \
    --libdir=/usr/lib \
    --enable-shared

printInfo "Building zlib"
serpentChroot make -j "${SERPENT_BUILD_JOBS}"

serpentChroot make -j "${SERPENT_BUILD_JOBS}" install
