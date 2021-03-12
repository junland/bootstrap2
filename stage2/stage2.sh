#!/usr/bin/env bash

########################################################################
#                                                                      #
# Stage: Two                                                           #
#                                                                      #
# Our aim here is to use stage1's cross-compiler, to cross-compile a   #
# minimal support system, stage3. We build a number of libraries,      #
# utilities and headers to provide a very basic chroot environment.    #
#                                                                      #
# We also rebuild the native compiler for this chroot, from the stage1 #
# compiler. The end result from stage2 will be used in the chroot to   #
# natively build all of stage3.                                        #
#                                                                      #
########################################################################

export SERPENT_STAGE_NAME="stage2"

. $(dirname $(realpath -s $0))/../lib/build.sh

executionPath=$(dirname $(realpath -s $0))

COMPONENTS=(
    "root"
    "headers"
    "glibc"
    "zlib"
    "binutils"
    "gcc"
    "toolchain"
    "ncurses"
    "bash"
    "gzip"
    "xz"
    "util-linux"
    "coreutils"
    "autoconf"
    "automake"
    "m4"
    "make"
    "gawk"
    "grep"
    "sed"
    "patch"
    "less"
    "which"
    "slibtool"
)

prefetchSources

for component in ${COMPONENTS[@]} ; do
    /usr/bin/env -S -i SERPENT_TARGET="${SERPENT_TARGET}" SERPENT_LIBC="glibc" bash --norc --noprofile "${executionPath}/${component}.sh"  || serpentFail "Building ${component} failed"
done
