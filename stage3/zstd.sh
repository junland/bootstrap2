#!/bin/true
set -e

. $(dirname $(realpath -s $0))/common.sh

extractSource zstd
serpentChrootCd zstd-*


printInfo "Building zstd"
serpentChroot make -j "${SERPENT_BUILD_JOBS}"

printInfo "Installing zstd"
serpentChroot make -j "${SERPENT_BUILD_JOBS}" install PREFIX=/usr LIBDIR=/usr/lib
