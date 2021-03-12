#!/bin/true
set -e

. $(dirname $(realpath -s $0))/common.sh

if [[ "${SERPENT_LIBC}" != "glibc" ]]; then
    printInfo "Skipping bash with non-glibc libc"
    exit 0
fi

extractSource bash
serpentChrootCd bash-*

printInfo "Configuring bash"
serpentChroot ./configure \
    --prefix=/usr \
    --sysconfdir=/etc \
    --libdir=/usr/lib \
    --bindir=/usr/bin \
    --sbindir=/usr/sbin \
    --datadir=/usr/share \
    --build="${SERPENT_TRIPLET}" \
    --host="${SERPENT_TRIPLET}" \
    --without-bash-malloc \
    --enable-nls

printInfo "Building bash"
serpentChroot make -j3

serpentChroot make -j3 install
ln -svf bash "${SERPENT_INSTALL_DIR}/usr/bin/sh"
