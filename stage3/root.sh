#!/bin/true
set -e

. $(dirname $(realpath -s $0))/common.sh

printInfo "Configuring root filesystem layout"

install -v -D -d -m 00755 "${SERPENT_INSTALL_DIR}"/usr/{bin,lib,share,sbin,include}
install -v -D -d -m 00755 "${SERPENT_INSTALL_DIR}"/{etc,proc,run,var,sys,dev,tmp}

install -v -D -d -m 00755 "${SERPENT_INSTALL_DIR}/run/lock"
ln -sv ../run/lock "${SERPENT_INSTALL_DIR}/var/lock"

ln -sv lib "${SERPENT_INSTALL_DIR}/usr/lib64"
ln -sv usr/bin "${SERPENT_INSTALL_DIR}/bin"
ln -sv usr/sbin "${SERPENT_INSTALL_DIR}/sbin"
ln -sv usr/lib "${SERPENT_INSTALL_DIR}/lib"
ln -sv usr/lib64 "${SERPENT_INSTALL_DIR}/lib64"


printInfo "Constructing device nodes"

# TTY support
mknod -m 622 "${SERPENT_INSTALL_DIR}"/dev/console c 5 1
mknod -m 666 "${SERPENT_INSTALL_DIR}"/dev/ptmx c 5 2
mknod -m 666 "${SERPENT_INSTALL_DIR}"/dev/tty c 5 0
chown -v root:tty "${SERPENT_INSTALL_DIR}"/dev/{console,ptmx,tty}

# Runtime support for random/null/zero
mknod -m 666 "${SERPENT_INSTALL_DIR}"/dev/null c 1 3
mknod -m 666 "${SERPENT_INSTALL_DIR}"/dev/zero c 1 5
mknod -m 444 "${SERPENT_INSTALL_DIR}"/dev/random c 1 8
mknod -m 444 "${SERPENT_INSTALL_DIR}"/dev/urandom c 1 9

printInfo "Creating runtime device links"

# runtime support
ln -svf /proc/self/fd "${SERPENT_INSTALL_DIR}"/dev/fd
ln -svf /proc/self/fd/0 "${SERPENT_INSTALL_DIR}"/dev/stdin
ln -svf /proc/self/fd/1 "${SERPENT_INSTALL_DIR}"/dev/stdout
ln -svf /proc/self/fd/2 "${SERPENT_INSTALL_DIR}"/dev/stderr
ln -svf /proc/kcore "${SERPENT_INSTALL_DIR}"/dev/core

printInfo "Stashing /bin/sh compat link"

if [[ "${SERPENT_LIBC}" == "musl" ]]; then
    ln -svf /serpent/usr/bin/dash "${SERPENT_INSTALL_DIR}/usr/bin/sh"
else
    ln -sfv /serpent/usr/bin/bash "${SERPENT_INSTALL_DIR}/usr/bin/sh"
fi
