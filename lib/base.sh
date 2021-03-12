#!/bin/true

# Common functionality between all stages

export SERPENT_CHROOT_DIR="/"

# Emit a warning to tty
function printWarning()
{
    echo -en '\e[1m\e[93m[WARNING]\e[0m '
    echo -e $*
}

# Emit an error to tty
function printError()
{
    echo -en '\e[1m\e[91m[ERROR]\e[0m '
    echo -e $*
}

# Emit info to tty
function printInfo()
{
    echo -en '\e[1m\e[94m[INFO]\e[0m '
    echo -e $*
}

# Failed to do a thing. Exit fatally.
function serpentFail()
{
    printError $*
    [ "${EUID}" -eq "0" ] && takeDownMounts
    exit 1
}

# Check tools can be found
function requireTools()
{
    for tool in $* ; do
        which "${tool}" &>/dev/null  || serpentFail "Missing host executable: ${tool}"
    done
}

# Check we're running as the root user
function checkRootUser()
{
    [ "${EUID}" -eq "0" ] || serpentFail "$0: Must be run via sudo"
    [ ! -z "${SUDO_USER}" ] || serpentFail "SUDO_USER incorrectly set"
}

# Create ancillary helpers
function createMountDirs()
{
    [ ! -z "${SERPENT_INSTALL_DIR}" ] || serpentFail "Missing SERPENT_INSTALL_DIR"

    install -D -d -m 00755 "${SERPENT_INSTALL_DIR}/dev/pts" || serpentFail "Failed to construct ${SERPENT_INSTALL_DIR}/dev/pts"
    install -D -d -m 00755 "${SERPENT_INSTALL_DIR}/proc" || serpentFail "Failed to construct ${SERPENT_INSTALL_DIR}/proc"
    install -D -d -m 00755 "${SERPENT_INSTALL_DIR}/sys" || serpentFail "Failed to construct ${SERPENT_INSTALL_DIR}/sys"
    install -D -d -m 00755 "${SERPENT_INSTALL_DIR}/serpent" || serpentFail "Failed to construct ${SERPENT_INSTALL_DIR}/serpent"
    install -D -d -m 00755 "${SERPENT_INSTALL_DIR}/build" || serpentFail "Failed to construct ${SERPENT_INSTALL_DIR}/build"
    install -D -d -m 00755 "${SERPENT_INSTALL_DIR}/os" || serpentFail "Failed to construct ${SERPENT_INSTALL_DIR}/os"
    install -D -d -m 00755 "${SERPENT_INSTALL_DIR}/stones" || serpentFail "Failed to construct ${SERPENT_INSTALL_DIR}/stones"
}

# Bring up required bindmounts for functional chroot environment
function bringUpMounts()
{
    printInfo "Bringing up the mounts"
    createMountDirs

    local stage2tree=$(getInstallDir 2)
    local stage3tree=$(getInstallDir 3)

    mount -v --bind /dev/pts "${stage3tree}/dev/pts" || serpentFail "Failed to bind-mount /dev/pts"
    mount -v --bind /sys "${stage3tree}/sys" || serpentFail "Failed to bind-mount /sys"
    mount -v --bind /proc "${stage3tree}/proc" || serpentFail "Failed to bind-mount /proc"

    if [ "${SERPENT_STAGE_NAME}" == "stage3" ]; then
        mount -v --bind -o ro "${stage2tree}" "${stage3tree}/serpent" || serpentFail "Failed to bind-mount /serpent"
        mount -v -o remount,ro,bind "${stage3tree}/serpent" || serpentFail "Failed to make /serpent read-only"
        mount -v --bind "${SERPENT_BUILD_DIR}" "${stage3tree}/build" || serpentFail "Failed to bind-mount /build"
    fi

    if [ "${SERPENT_STAGE_NAME}" == "stage4" ]; then
        mount -v --bind "${SERPENT_BUILD_DIR}/stones" "${stage3tree}/stones" || serpentFail "Failed to bind-mount /stones"
    fi

}

function installQemuStatic()
{
        printInfo "Installing qemu-user-static for cross-compilation chroot"
        install -D -m 00755 $(which ${SERPENT_QEMU_USER_STATIC}) "${SERPENT_INSTALL_DIR}/usr/bin/${SERPENT_QEMU_USER_STATIC}" || serpentFail "Failed to install qemu-user-static"
}

# Helper to ensure something *does* get unmounted
function serpentUnmount()
{
    local target="${1}"
    [ ! -z "${target}" ] || serpentFail "No mountpoint specified"

    umount "${target}"
    if [[ "$?" != 0 ]]; then
        sleep 1
        umount "${target}"
    fi
    if [[ "$?" != "0" ]]; then
        printWarning "Lazy-unmounting ${target}"
        umount -l "${target}" || :
    fi
}

# Take down the mounts again
function takeDownMounts()
{
    set +e

    local stage3tree=$(getInstallDir 3)
    printInfo "Taking down the mounts"
    serpentUnmount "${stage3tree}/build"
    serpentUnmount "${stage3tree}/serpent"
    serpentUnmount "${stage3tree}/dev/pts"
    serpentUnmount "${stage3tree}/sys"
    serpentUnmount "${stage3tree}/proc"
    serpentUnmount "${stage3tree}/stones"
}

# chroot helper. In future we should expand to support qemu-static.
function serpentChroot()
{
    if [[ -e "${SERPENT_INSTALL_DIR}/serpent/usr/bin/dash" ]]; then
        LD_LIBRARY_PATH="/serpent/usr/lib" PATH="${PATH}:/serpent/usr/bin" chroot "${SERPENT_INSTALL_DIR}" /serpent/usr/bin/dash -c "cd \"${SERPENT_CHROOT_DIR}\"; $*;"
    else
        LD_LIBRARY_PATH="/serpent/usr/lib" PATH="${PATH}:/serpent/usr/bin" chroot "${SERPENT_INSTALL_DIR}" /serpent/usr/bin/bash -c "cd \"${SERPENT_CHROOT_DIR}\"; $*;"

    fi
}

# Set the chroot dir
function serpentChrootCd()
{
    export SERPENT_CHROOT_DIR="/build/${SERPENT_BUILD_NAME}/$1"
}

# Take down the mounts again
function createDownloadStore()
{
    local stage3tree=$(getInstallDir 3)

    for i in ${SERPENT_DOWNLOAD_DIR}/*; do
        SHASUM=$(sha256sum "${i}" | cut -f1 -d' ')
        FIRST=$(echo ${SHASUM:0:5})
        LAST=$(echo ${SHASUM:59:64})
        if [ ! -f "${stage3tree}/os/store/downloads/v1/${FIRST}/${LAST}/${SHASUM}" ]; then
            mkdir -p "${stage3tree}/os/store/downloads/v1/${FIRST}/${LAST}"
            install -D ${i} "${stage3tree}/os/store/downloads/v1/${FIRST}/${LAST}/${SHASUM}"
        fi
        unset SHASUM FIRST LAST
    done
}

# Stash binutils binaries in subdir
function stashBinutils()
{
    local stage3tree=$(getInstallDir 3)
    local stash_dir="${1}"

    binutils_files="addr2line ar as c++filt elfedit gprof ld ld.bfd nm objcopy objdump ranlib readelf size strings strip"
    mkdir -p ${stage3tree}/usr/bin/${stash_dir}
    for file in ${binutils_files}; do
        if [ -f ${stage3tree}/usr/bin/${file} ]; then
            mv ${stage3tree}/usr/bin/${file} ${stage3tree}/usr/bin/${stash_dir}/
        fi
    done
}

# Restore binutils binaries from subdir
function restoreBinutils()
{
    local stage3tree=$(getInstallDir 3)
    local stash_dir="${1}"

    binutils_files="addr2line ar as c++filt elfedit gprof ld ld.bfd nm objcopy objdump ranlib readelf size strings strip"
    for file in ${binutils_files}; do
        if [ -f ${stage3tree}/usr/bin/${stash_dir}/${file} ]; then
            cp -f ${stage3tree}/usr/bin/${stash_dir}/${file} ${stage3tree}/usr/bin/
        fi
    done
}

# Stash GCC binaries in subdir
function stashGcc()
{
    local stage3tree=$(getInstallDir 3)
    local stash_dir="${1}"

    gcc_files="cc c++ cpp g++ gcc gcc-ar gcc-nm gcc-ranlib gcov gcov-dump gcov-tool lto-dump x86_64-serpent-linux-c++ x86_64-serpent-linux-g++ x86_64-serpent-linux-gcc x86_64-serpent-linux-gcc-10 x86_64-serpent-linux-gcc-ar x86_64-serpent-linux-gcc-nm x86_64-serpent-linux-gcc-ranlib"
    mkdir -p ${stage3tree}/usr/bin/${stash_dir}
    for file in ${gcc_files}; do
        if [ -f ${stage3tree}/usr/bin/${file} ]; then
            mv ${stage3tree}/usr/bin/${file} ${stage3tree}/usr/bin/${stash_dir}/
        fi
    done
}

# Restore GCC binaries from subdir
function restoreGcc()
{
    local stage3tree=$(getInstallDir 3)
    local stash_dir="${1}"

    gcc_files="cc c++ cpp g++ gcc gcc-ar gcc-nm gcc-ranlib gcov gcov-dump gcov-tool lto-dump x86_64-serpent-linux-c++ x86_64-serpent-linux-g++ x86_64-serpent-linux-gcc x86_64-serpent-linux-gcc-10 x86_64-serpent-linux-gcc-ar x86_64-serpent-linux-gcc-nm x86_64-serpent-linux-gcc-ranlib"
    for file in ${gcc_files}; do
        if [ -f ${stage3tree}/usr/bin/${stash_dir}/${file} ]; then
            cp -f ${stage3tree}/usr/bin/${stash_dir}/${file} ${stage3tree}/usr/bin/
        fi
    done
}

# Tightly control the path
export PATH="/usr/bin:/bin/:/sbin:/usr/sbin"

export SERPENT_ROOT_DIR="$(dirname $(dirname $(realpath -s ${BASH_SOURCE[0]})))"

export SERPENT_BUILD_ROOT="${SERPENT_ROOT_DIR}/build"
export SERPENT_DOWNLOAD_DIR="${SERPENT_ROOT_DIR}/downloads"
export SERPENT_INSTALL_ROOT="${SERPENT_ROOT_DIR}/install"
export SERPENT_SOURCES_DIR="${SERPENT_ROOT_DIR}/sources"
export SERPENT_PATCHES_DIR="${SERPENT_ROOT_DIR}/patches"

# Basic validation.
[ -d "${SERPENT_SOURCES_DIR}" ] || serpentFail "Missing source tree"

export LANG="C"
export LC_ALL="C"
