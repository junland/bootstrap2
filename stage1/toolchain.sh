#!/bin/true
set -e

. $(dirname $(realpath -s $0))/common.sh

export TOOLCHAIN_VERSION="11.0.1"

printInfo "Extracting toolchain requirements"
extractSource clang
extractSource compiler-rt
extractSource libcxx
extractSource libcxxabi
extractSource libunwind
extractSource lld
extractSource llvm

ln -sv "clang-${TOOLCHAIN_VERSION}.src" clang
ln -sv "compiler-rt-${TOOLCHAIN_VERSION}.src" compiler-rt
ln -sv "libcxx-${TOOLCHAIN_VERSION}.src" libcxx
ln -sv "libcxxabi-${TOOLCHAIN_VERSION}.src" libcxxabi
ln -sv "libunwind-${TOOLCHAIN_VERSION}.src" libunwind
ln -sv "lld-${TOOLCHAIN_VERSION}.src" lld
ln -sv "llvm-${TOOLCHAIN_VERSION}.src" llvm

if [[ "${SERPENT_LIBC}" == "musl" ]]; then
    pushd clang
    patch -p1 < "${SERPENT_PATCHES_DIR}/clang/0001-ToolChains-Linux-Use-correct-musl-path-on-Serpent-OS.patch"
    popd
fi

pushd llvm

mkdir build && pushd build

export CFLAGS="-fPIC -O2 -pipe"
export CXXFLAGS="${CFLAGS}"

export llvmopts="
    -DCMAKE_INSTALL_PREFIX=/usr \
    -DLLVM_ENABLE_PROJECTS='clang;compiler-rt;libcxx;libcxxabi;libunwind;lld;llvm' \
    -DDEFAULT_SYSROOT="${SERPENT_INSTALL_DIR}" \
    -DCMAKE_BUILD_TYPE=Release \
    -DLLVM_ENABLE_LIBXML2=OFF \
    -DLLVM_TARGET_ARCH="${SERPENT_TARGET_ARCH}" \
    -DLLVM_DEFAULT_TARGET_TRIPLE="${SERPENT_TRIPLET}" \
    -DLLVM_TARGETS_TO_BUILD="${SERPENT_TARGET_LLVM_BACKEND}" \
    -DLLVM_INCLUDE_TESTS=OFF \
    -DCLANG_DEFAULT_CXX_STDLIB=libc++ \
    -DCLANG_DEFAULT_LINKER=lld \
    -DCLANG_DEFAULT_OBJCOPY=llvm-objcopy \
    -DCLANG_DEFAULT_RTLIB=compiler-rt \
    -DLLVM_INSTALL_BINUTILS_SYMLINKS=ON \
    -DLLVM_INSTALL_CCTOOLS_SYMLINKS=ON
    -DCOMPILER_RT_USE_BUILTINS_LIBRARY=ON \
    -DCOMPILER_RT_USE_LIBCXX=ON \
    -DLLVM_ENABLE_LIBCXX=ON \
    -DLLVM_STATIC_LINK_CXX_STDLIB=ON \
    -DSANITIZER_CXX_ABI=libc++ \
    -DLIBCXX_INSTALL_SUPPORT_HEADERS=ON \
    -DLIBCXX_ENABLE_SHARED=ON \
    -DLIBCXX_ENABLE_STATIC=OFF \
    -DLIBCXX_USE_COMPILER_RT=ON \
    -DLIBCXX_ENABLE_STATIC_ABI_LIBRARY=ON \
    -DLIBCXX_STATICALLY_LINK_ABI_IN_STATIC_LIBRARY=ON \
    -DLIBCXXABI_USE_LLVM_UNWINDER=ON \
    -DLIBCXXABI_USE_COMPILER_RT=ON \
    -DLIBCXXABI_ENABLE_SHARED=OFF \
    -DLIBCXXABI_INSTALL_LIBRARY=ON \
    -DLIBUNWIND_USE_COMPILER_RT=ON \
    -DCOMPILER_RT_BUILD_LIBFUZZER=OFF \
    -DCOMPILER_RT_BUILD_PROFILE=OFF \
    -DCOMPILER_RT_BUILD_SANITIZERS=OFF \
    -DCOMPILER_RT_BUILD_XRAY=OFF \
    -DCOMPILER_RT_BUILD_BUILTINS=ON \
    -DLLVM_USE_SANITIZER=OFF \
    -DLLVM_ENABLE_UNWIND_TABLES=OFF \
    -DLLVM_INCLUDE_BENCHMARKS=OFF \
    -DLLVM_INCLUDE_UTILS=OFF \
    -DCLANG_DEFAULT_UNWINDLIB="libunwind" \
    -DLLVM_OPTIMIZED_TABLEGEN=ON \
    -DLLVM_BUILD_TOOLS=OFF \
    -DCLANG_BUILD_TOOLS=OFF"

cmake -G Ninja ../ \
    ${llvmopts} \
    -DLLVM_BUILD_LLVM_DYLIB=ON \
    -DLLVM_LINK_LLVM_DYLIB=ON

ninja -j "${SERPENT_BUILD_JOBS}" -v
ninja -j "${SERPENT_BUILD_JOBS}" -v llvm-config

printInfo "Installing toolchain"
DESTDIR="${SERPENT_INSTALL_DIR}" ninja install -j "${SERPENT_BUILD_JOBS}" -v

cmake -G Ninja ../ \
    ${llvmopts} \
    -DLLVM_BUILD_LLVM_DYLIB=OFF \
    -DLLVM_LINK_LLVM_DYLIB=OFF \
    -DCLANG_LINK_CLANG_DYLIB=OFF
ninja -j "${SERPENT_BUILD_JOBS}" -v lld clang
cp "${SERPENT_BUILD_DIR}"/llvm/build/bin/* "${SERPENT_INSTALL_DIR}/usr/bin/"

# Only install if binutils ld not already present
if [ ! -f "${SERPENT_INSTALL_DIR}/usr/bin/ld" ]; then
    printInfo "Setting ld.lld as default ld"
    ln -svf ld.lld "${SERPENT_INSTALL_DIR}/usr/bin/ld"
fi
