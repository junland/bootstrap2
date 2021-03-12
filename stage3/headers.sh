#!/bin/true
set -e

. $(dirname $(realpath -s $0))/common.sh

activateStage1Compiler

extractSource linux
cd linux-*

if [[ "${SERPENT_LIBC}" == "glibc" ]]; then
    export SERPENT_STAGE1_TREE=$(getInstallDir "1")
    export PATH="${SERPENT_STAGE1_TREE}/usr/binutils/bin:${PATH}"
fi


printInfo "Configuring headers"
export ARCH="${SERPENT_TARGET_ARCH}"
make mrproper
make headers
find usr/include -name '.*' -delete
rm -vf usr/include/Makefile

printInfo "Installing headers"
install -D -d -m 00755 "${SERPENT_INSTALL_DIR}/usr/include"
cp -Rv usr/include "${SERPENT_INSTALL_DIR}/usr/."
