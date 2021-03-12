#!/bin/true
set -e

. $(dirname $(realpath -s $0))/common.sh

extractSource pkgconf
serpentChrootCd pkgconf-*

printInfo "Configuring pkgconf"
serpentChroot ./configure \
    --build="${SERPENT_TRIPLET}" \
    --host="${SERPENT_TRIPLET}" \
    --prefix=/usr \
    --sysconfdir=/etc \
    --libdir=/usr/lib \
    --bindir=/usr/bin \
    --sbindir=/usr/sbin \
    --datadir=/usr/share \
    --with-system-libdir=/usr/lib \
    --with-system-includedir=/usr/include \
    --includedir=/usr/include \
    --enable-static \
    --disable-shared

printInfo "Building pkgconf"
serpentChroot make -j "${SERPENT_BUILD_JOBS}"

serpentChroot make -j "${SERPENT_BUILD_JOBS}" install

printInfo "Setting pkgconf as default pkg-config"
ln -svf pkgconf "${SERPENT_INSTALL_DIR}/usr/bin/pkg-config"
