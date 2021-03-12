#!/usr/bin/env bash

########################################################################
#                                                                      #
# Stage: Three                                                         #
#                                                                      #
# We construct a chroot environment that has an empty layout, that is  #
# used to natively build the final system. To achieve this, some quick #
# compatibility work is done, such as building musl and the system     #
# headers.
#
# We bind-mount the stage2 support environment to the /serpent tree    #
# and add it to the end of the PATH environmental variable. This lets  #
# us use the native compiler, libs, etc, to natively build all of our  #
# needed software and install to the root of the tree.                 #
#                                                                      #
########################################################################

export SERPENT_STAGE_NAME="stage3"

. $(dirname $(realpath -s $0))/../lib/build.sh

executionPath=$(dirname $(realpath -s $0))

COMPONENTS=(
    "root"
    "headers"
    "${SERPENT_LIBC}"
    "diffutils"
    "zlib"
    "xz"
    "file"
    "findutils"
    "libarchive"
    "binutils"
    "gcc"
    "attr"
    "acl"
    "ncurses"
    "bash"
    "slibtool"
    "gzip"
    "less"
    "sed"
    "gawk"
    "grep"
    "patch"
    "which"
    "m4"
    "make"
    "perl"
    "autoconf"
    "automake"
    "pkgconf"
    "coreutils"
    "util-linux"
    "cmake"
    "ninja"
    "libcap"
    "gperf"
    "libffi"
    "python"
    "meson"
    "linux-pam"
    "systemd"
    "shadow"
    "expat"
    "dbus"
    "dbus-broker"
    "util-linux2"
    "systemd"
    "dbus-broker"
    "toolchain"
    "libxml2"
    "ldc"
    "zstd"
    "nano"
    "bison"
)

checkRootUser

requireTools "mknod"

prefetchSources
mkdir -p "${SERPENT_BUILD_DIR}" || serpentFail "Failed to create directory ${SERPENT_BUILD_DIR}"
bringUpMounts

if [[ "${SERPENT_TARGET_ARCH}" != "${SERPENT_ARCH}" ]]; then
        requireTools "${SERPENT_QEMU_USER_STATIC}"
        installQemuStatic
fi

# Install the config.site file for autotools caching
cp "${executionPath}/config.site" "${SERPENT_INSTALL_DIR}/"

for component in ${COMPONENTS[@]} ; do
    /usr/bin/env -S -i SERPENT_TARGET="${SERPENT_TARGET}" SERPENT_LIBC="${SERPENT_LIBC}" bash --norc --noprofile "${executionPath}/${component}.sh"  || serpentFail "Building ${component} failed"
done

takeDownMounts