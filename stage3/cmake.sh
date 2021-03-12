#!/bin/true
set -e

. $(dirname $(realpath -s $0))/common.sh

extractSource cmake
serpentChrootCd cmake-*


printInfo "Configuring cmake"

serpentChroot ./configure \
    --prefix=/usr \
    --parallel="${SERPENT_BUILD_JOBS}" \
    -- -DCMAKE_USE_OPENSSL=OFF

printInfo "Building cmake"
serpentChroot make -j "${SERPENT_BUILD_JOBS}"

printInfo "Installing cmake"
serpentChroot make -j "${SERPENT_BUILD_JOBS}" install
