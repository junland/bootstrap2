#!/bin/true
set -e

. $(dirname $(realpath -s $0))/common.sh

if [[ "${SERPENT_LIBC}" != "glibc" ]]; then
    printInfo "Skipping gcc with non-glibc libc"
    exit 0
fi

extractSource gcc
pushd gcc-*

printInfo "Extracting gcc requirements"
extractSource mpfr
extractSource mpc
extractSource gmp
#extractSource isl

ln -sv "mpfr-4.1.0" mpfr
ln -sv "mpc-1.2.1" mpc
ln -sv "gmp-6.2.1" gmp
#ln -sv "isl-0.21" isl

mkdir -p build
popd

unset CONFIG_SITE
export LD="ld.bfd"
export AR="ar"
export RANLIB="ranlib"
export AS="as"
export NM="nm"
export OBJDUMP="objdump"
export READELF="readelf"
export STRIP="strip"
export CC="gcc -B/usr/lib -isystem /usr/include -isystem /serpent/usr/include"
export CXX="g++ -B/usr/lib -isystem /usr/include -isystem /usr/include -isystem /serpent/usr/include/c++/10.2.0 -isystem /serpent/usr/include/c++/10.2.0/x86_64-linux-gnu"

ln -svf /serpent/usr/bin/cpp "${SERPENT_INSTALL_DIR}/lib/cpp"

export LDFLAGS="-L/usr/lib -L/serpent/usr/lib -B/usr/lib -B/serpent/usr/lib -isystem /usr/include -isystem /serpent/usr/include"
export CFLAGS="${CFLAGS} ${LDFLAGS}"
export CPPFLAGS="${CFLAGS} ${LDFLAGS}"
export CXXFLAGS="${CXXFLAGS} ${LDFLAGS} -isystem /serpent/usr/include/c++/10.2.0 -isystem /serpent/usr/include/c++/10.2.0/x86_64-linux-gnu"
export PATH="/usr/binutils/bin:${PATH}"
export COMPILER_PATH="/usr/binutils/bin:/usr/bin:/serpent/usr/bin"
export LIBRARY_PATH="/usr/lib"

serpentChrootCd gcc-*/build

printInfo "Configuring gcc"
serpentChroot ../configure --prefix=/usr \
    --bindir=/usr/bin \
    --sysconfdir=/etc \
    --libdir=/usr/lib \
    --sbindir=/usr/sbin \
    --datadir=/usr/share \
    --includedir=/usr/include \
    --build="${SERPENT_TRIPLET}" \
    --host="${SERPENT_TRIPLET}" \
    --disable-bootstrap \
    --enable-shared \
    --enable-static \
    --enable-threads \
    --disable-multilib \
    --disable-werror \
    --with-gcc-major-version-only \
    --enable-gnu-indirect-function \
    --enable-plugin \
    --enable-ld=default \
    --enable-clocale=gnu \
    --with-linker-hash-style=both \
    --with-gnu-ld \
    --enable-languages=c,c++ \
    PATH="/usr/binutils/bin:/serpent/usr/bin:/serpent/usr/sbin:/usr/bin:/usr/sbin"

printInfo "Building gcc"
serpentChroot make -j "${SERPENT_BUILD_JOBS}"

printInfo "Installing gcc"
serpentChroot make -j "${SERPENT_BUILD_JOBS}" install
ln -svf /usr/bin/cpp "${SERPENT_INSTALL_DIR}/lib/cpp"

stashBinutils gnu-binutils
stashGcc gnu-gcc
