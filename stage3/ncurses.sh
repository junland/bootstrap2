#!/bin/true
set -e

. $(dirname $(realpath -s $0))/common.sh

extractSource ncurses
unset CONFIG_SITE

printInfo "Configuring ncurses"
serpentChrootCd ncurses*
serpentChroot ./configure \
    --host="${SERPENT_TRIPLET}" \
    --build="${SERPENT_TRIPLET}" \
    --prefix=/usr \
    --sysconfdir=/etc \
    --libdir=/usr/lib \
    --bindir=/usr/bin \
    --sbindir=/usr/sbin \
    --datadir=/usr/share \
    --without-debug \
    --disable-rpath \
    --disable-stripping \
    --with-shared \
    --without-ada \
    --enable-widec \
    --enable-largefile \
    --enable-db-install \
    --enable-symlinks \
    --with-pkg-config-libdir=/usr/lib/pkgconfig \
    --with-cxx-binding \
    PKG_CONFIG_LIBDIR=/usr/lib/pkgconfig

printInfo "Building ncurses"
serpentChroot make -j${SERPENT_BUILD_JOBS}
serpentChroot make -j${SERPENT_BUILD_JOBS} install

echo "INPUT(-lncursesw)" > "${SERPENT_INSTALL_DIR}/usr/lib/libncurses.so"
echo "INPUT(-lncursesw)" > "${SERPENT_INSTALL_DIR}/usr/lib/libcurses.so"
