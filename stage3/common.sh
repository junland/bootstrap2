#!/bin/true

export SERPENT_STAGE_NAME="stage3"

. $(dirname $(realpath -s $0))/../lib/build.sh

prepareBuild

export TERM="xterm"
export CC="clang"
export CXX="clang++"
export LD="ld.lld"
export AR="llvm-ar"
export NM="llvm-nm"
export OBJDUMP="llvm-objdump"
export RANLIB="llvm-ranlib"
export READELF="llvm-readelf"
export STRIP="llvm-strip"
export CFLAGS="${SERPENT_TARGET_CFLAGS}"
export CXXFLAGS="${SERPENT_TARGET_CXXFLAGS}"
export LDFLAGS="${SERPENT_TARGET_LDFLAGS}"
export CONFIG_SITE=/config.site
