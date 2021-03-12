#!/bin/true
set -e

. $(dirname $(realpath -s $0))/common.sh

extractSource coreutils
serpentChrootCd coreutils-*
pushd coreutils-*


printInfo "Configuring coreutils"
# Fix aarch64 SYS_getdents regression
patch -p1 < "${SERPENT_PATCHES_DIR}/coreutils/coreutils_8_31_ls.patch"
# LFS: Fix issue with autoconf 2.70 update
echo '# deleted' > m4/std-gnu11.m4

export FORCE_UNSAFE_CONFIGURE=1
serpentChroot ./configure \
    --build="${SERPENT_TRIPLET}" \
    --host="${SERPENT_TRIPLET}" \
    --enable-largefile \
    --prefix=/usr \
    --sysconfdir=/etc \
    --libdir=/usr/lib \
    --bindir=/usr/bin \
    --sbindir=/usr/sbin \
    --datadir=/usr/share \
    --enable-single-binary


printInfo "Building coreutils"
serpentChroot make -j "${SERPENT_BUILD_JOBS}"

printInfo "Installing coreutils"
serpentChroot make -j "${SERPENT_BUILD_JOBS}" install
