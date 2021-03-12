#!/bin/true
set -e

. $(dirname $(realpath -s $0))/common.sh

if [[ "${SERPENT_TARGET_ARCH}" == "${SERPENT_ARCH}" ]]; then
    printInfo "Skipping compiler-rt on native architecture"
    exit 0
fi

printInfo "Building compiler-rt builtins for cross-compilation"

export PATH="${SERPENT_INSTALL_DIR}/usr/bin:$PATH"
export CC="clang"
export CXX="clang++"

export CFLAGS="${SERPENT_TARGET_CFLAGS}"
export CXXFLAGS="${SERPENT_TARGET_CXXFLAGS}"
export AR="llvm-ar"
export RANLIB="llvm-ranlib"
export STRIP="llvm-strip"
export TOOLCHAIN_VERSION="11.0.1"

extractSource compiler-rt

# Handle musl-specific bootstrap of compiler-rt
if [[ "${SERPENT_LIBC}" == "musl" ]]; then
    printInfo "Pre-configuring musl for cross-target headers"
    extractSource musl
    pushd musl*
    ./configure --prefix=/usr \
        --target="${SERPENT_TRIPLET}" \
        --build="${SERPENT_TRIPLET}" \
        --enable-optimize=auto \
        --enable-visibility \

    printInfo "Initial non-linked build of musl"
    make -j "${SERPENT_BUILD_JOBS}" obj/include/bits/alltypes.h obj/include/bits/syscall.h

    printInfo "Expanding flags to musl base"
    export MUSL_EXTRA_FLAGS="-I$(pwd)/include -I$(pwd)/arch/generic -I$(pwd)/arch/${SERPENT_TARGET_MUSL} -I$(pwd)/obj/include -Wno-unused-command-line-argument -Wno-error"
    export CFLAGS="${CFLAGS} ${MUSL_EXTRA_FLAGS}"
    export CXXFLAGS="${CXXFLAGS} ${MUSL_EXTRA_FLAGS}"
    popd

fi

printInfo "Configuring compiler-rt builtins"
pushd compiler-rt*
mkdir build && pushd build
cmake .. -G Ninja  \
    -DCOMPILER_RT_BUILD_BUILTINS=ON \
    -DCOMPILER_RT_BUILD_SANITIZERS=OFF \
    -DCOMPILER_RT_BUILD_XRAY=OFF \
    -DCOMPILER_RT_BUILD_LIBFUZZER=OFF \
    -DCOMPILER_RT_BUILD_PROFILE=OFF \
    -DCOMPILER_RT_DEFAULT_TARGET_ONLY=ON \
    -DCMAKE_C_COMPILER_TARGET="${SERPENT_TRIPLET}" \
    -DCMAKE_ASM_COMPILER_TARGET="${SERPENT_TRIPLET}" \
    -DCMAKE_C_FLAGS="${CFLAGS}" \
    -DCMAKE_ASM_FLAGS="${CFLAGS}" \
    -DCOMPILER_RT_STANDALONE_BUILD=ON \
    -DCMAKE_TRY_COMPILE_TARGET_TYPE=STATIC_LIBRARY \
    -DCOMPILER_RT_INCLUDE_TESTS=OFF \
    -DLLVM_CONFIG_PATH="${SERPENT_INSTALL_DIR}/usr/bin/llvm-config" \
    -DCMAKE_C_COMPILER=clang \
    -DCMAKE_CXX_COMPILER=clang++ \
    -DCMAKE_AR="${SERPENT_INSTALL_DIR}/usr/bin/ar" \
    -DCMAKE_NM="${SERPENT_INSTALL_DIR}/usr/bin/llvm-nm" \
    -DCMAKE_RANLIB="${SERPENT_INSTALL_DIR}/usr/bin/llvm-ranlib"

ninja -j "${SERPENT_BUILD_JOBS}"

printInfo "Installing compiler-rt builtins"
install -D -d -m 00755 "${SERPENT_INSTALL_DIR}/usr/lib/clang/${TOOLCHAIN_VERSION}/lib/linux"
install -v -m 00644 lib/linux/*.a "${SERPENT_INSTALL_DIR}/usr/lib/clang/${TOOLCHAIN_VERSION}/lib/linux/."
install -v -m 00644 lib/linux/*.o "${SERPENT_INSTALL_DIR}/usr/lib/clang/${TOOLCHAIN_VERSION}/lib/linux/."
popd
