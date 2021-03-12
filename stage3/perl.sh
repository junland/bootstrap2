#!/bin/true
set -e

. $(dirname $(realpath -s $0))/common.sh

extractSource perl
serpentChrootCd perl-*


printInfo "Configuring perl"

serpentChroot ./Configure \
    -des \
    -Dprefix=/usr \
    -Dvendorprefix=/usr \
    -Dscriptdir=/usr/bin \
    -Duseshrplib \
    -Dusethreads \
    -Dcc=clang \
    -Dnoextensions=Encode


printInfo "Building perl"
serpentChroot make -j "${SERPENT_BUILD_JOBS}"

printInfo "Installing perl"
serpentChroot make -j "${SERPENT_BUILD_JOBS}" install
