#!/bin/true
set -e

. $(dirname $(realpath -s $0))/common.sh

if [[ "${SERPENT_LIBC}" == "musl" ]]; then
    printInfo "Skipping binutils with musl libc"
    exit 0
fi

extractSource binutils
cd binutils-*

export LD="ld.bfd"
export AR="ar"
export RANLIB="ranlib"
export AS="as"
export NM="nm"
export OBJDUMP="objdump"
export READELF="readelf"
export STRIP="strip"
export CC="gcc"
export CXX="g++"

export CFLAGS="${SERPENT_TARGET_CFLAGS}"
export CXXFLAGS="${SERPENT_TARGET_CXXFLAGS}"

export SERPENT_STAGE1_TREE=$(getInstallDir "1")
export PATH="${SERPENT_STAGE1_TREE}/usr/binutils/bin:${PATH}"

printInfo "Configuring binutils"
mkdir build && pushd build
../configure --prefix=/usr/binutils \
    --target="${SERPENT_TRIPLET}" \
    --host="${SERPENT_HOST}" \
    --libdir=/usr/lib \
    --includedir=/usr/include \
    --disable-multilib \
    --enable-deterministic-archives \
    --enable-plugins \
    --enable-lto \
    --disable-shared \
    --enable-static \
    --without-debuginfod \
    --enable-ld=default \
    --enable-secureplt \
    --enable-64-bit-bfd

printInfo "Building binutils"
make -j "${SERPENT_BUILD_JOBS}" tooldir=/usr/binutils

printInfo "Installing binutils"
make -j "${SERPENT_BUILD_JOBS}" tooldir=/usr/binutils install DESTDIR="${SERPENT_INSTALL_DIR}"
