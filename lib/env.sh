#/usr/bin/env -S -i bash --norc --noprofile

umask 022

export STRAP_SELECTED_TARGET=${STRAP_SELECTED_TARGET:-"x86_64"}
export STRAP_PJOBS=${STRAP_PJOBS:-"2"}

unset CC CXX AR AS RANLIB LD STRIP OBJCOPY OBJDUMP
unset CFLAGS CXXFLAGS LDFLAGS

export STRAP_ROOT_DIR="$(pwd)"
export STRAP_BUILD_DIR="${STRAP_ROOT_DIR}/build"
export STRAP_TARGETS_DIR="${STRAP_ROOT_DIR}/targets"
export STRAP_INSTALL_DIR="${STRAP_ROOT_DIR}/install"
export STRAP_SOURCES_DIR="${STRAP_ROOT_DIR}/sources"
export STRAP_PATCHES_DIR="${STRAP_ROOT_DIR}/sources/patches"
export STRAP_STAGE1_INSTALL_DIR="${STRAP_INSTALL_DIR}/stage1"
export STRAP_STAGE2_INSTALL_DIR="${STRAP_INSTALL_DIR}/stage2"
export STRAP_DEFAULT_PATH="/usr/bin:/bin:/sbin:/usr/sbin"

export LANG="C"
export LC_ALL="C"
export PATH=${STRAP_DEFAULT_PATH}