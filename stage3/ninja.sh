#!/bin/true
set -e

. $(dirname $(realpath -s $0))/common.sh

extractSource ninja
serpentChrootCd ninja-*


printInfo "Configuring ninja"

serpentChroot cmake . \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_PREFIX=/usr \

printInfo "Building ninja"
serpentChroot make -j "${SERPENT_BUILD_JOBS}"

printInfo "Installing ninja"
serpentChroot cp ninja /usr/bin/ninja
