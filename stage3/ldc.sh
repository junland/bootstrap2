#!/bin/true
set -e

. $(dirname $(realpath -s $0))/common.sh

export LDC_VERSION="1.24.0"

printInfo "Extracting ldc"
extractSource ldc
extractSource ldc-static-x86_64

pushd ldc-*
# Fix linker woes without gold
patch -p1 < "${SERPENT_PATCHES_DIR}/0001-Default-to-lld-but-don-t-pass-linker-to-compiler.patch"


printInfo "Configure ldc"
mkdir ldc-build && pushd ldc-build
serpentChrootCd ldc-${LDC_VERSION}-src/ldc-build
serpentChroot cmake -G "Ninja" .. \
    -DBUILD_SHARED_LIBS=ON \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_PREFIX=/usr \
    -DD_COMPILER="/build/ldc/ldc2-${LDC_VERSION}-linux-${SERPENT_TARGET_ARCH}/bin/ldmd2" \
    -DLDC_INSTALL_LTOPLUGIN=ON \
    -DLDC_INSTALL_LLVM_RUNTIME_LIBS=ON \
    -DLDC_LINK_MANUALLY=OFF \
    -DLDC_WITH_LLD=ON \
    -DCMAKE_EXE_LINKER_FLAGS="-fuse-ld=lld"

printInfo "Building ldc"
serpentChroot ninja -j "${SERPENT_BUILD_JOBS}" -v

printInfo "Installing ldc"
serpentChroot ninja install -j "${SERPENT_BUILD_JOBS}" -v
cp "${SERPENT_BUILD_DIR}/ldc2-${LDC_VERSION}-linux-${SERPENT_TARGET_ARCH}/bin/dub" "${SERPENT_INSTALL_DIR}/usr/bin/"
