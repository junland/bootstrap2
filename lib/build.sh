#!/bin/true

# Build stages functionality
export SERPENT_ROOT_DIR="$(dirname $(dirname $(realpath -s ${BASH_SOURCE[0]})))"

. "${SERPENT_ROOT_DIR}/lib/base.sh"

# Set the target Arch to import early for install dir
export SERPENT_TARGET=${SERPENT_TARGET:-"x86_64"}

# Define which libc we wish to use with this build
export SERPENT_LIBC=${SERPENT_LIBC:-"glibc"}

# Make sure the scripts are properly implemented.
[ ! -z "${SERPENT_STAGE_NAME}" ] || serpentFail "Stage name is not set"

# Stage specific directories
export SERPENT_BUILD_DIR="${SERPENT_BUILD_ROOT}/${SERPENT_STAGE_NAME}"
export SERPENT_INSTALL_DIR="${SERPENT_INSTALL_ROOT}/${SERPENT_TARGET}/${SERPENT_LIBC}/${SERPENT_STAGE_NAME}"
export SERPENT_BUILD_SCRIPT=$(basename "${0}")
export SERPENT_BUILD_NAME="${SERPENT_BUILD_SCRIPT%.sh}"
export SERPENT_BUILD_JOBS=$(nproc)

# Helper to get older stage tree
function getInstallDir()
{
    [ ! -z "${1}" ] || serpentFail "Incorrect use of getInstallDir"
    echo "${SERPENT_INSTALL_ROOT}/${SERPENT_TARGET}/${SERPENT_LIBC}/stage${1}"
}

# Verify the download is correct
function verifyDownload()
{
    [ ! -z "${1}" ] || serpentFail "Incorrect use of verifyDownload"
    sourceFile="${SERPENT_SOURCES_DIR}/${1}"
    [ -f "${sourceFile}" ] || serpentFail "Missing source file: ${sourceFile}"
    sourceURL="$(cat ${sourceFile} | cut -d ' ' -f 1)"
    sourceHash="$(cat ${sourceFile} | cut -d ' ' -f 2)"
    [ ! -z "${sourceURL}" ] || serpentFail "Missing URL for source: $1"
    [ ! -z "${sourceHash}" ] || serpentFail "Missing hash for source: $1"
    sourcePathBase=$(basename "${sourceURL}")
    sourcePath="${SERPENT_DOWNLOAD_DIR}/${sourcePathBase}"

    printInfo "Computing hash for ${sourcePathBase}"

    computeHash=$(sha256sum "${sourcePath}" | cut -d ' ' -f 1)
    [ $? -eq 0 ] || serpentFail "Failed to compute SHA256sum"

    if [ "${computeHash}" != "${sourceHash}" ]; then
        rm -v "${sourcePath}"
        serpentFail "Corrupt download: ${sourcePath}\nExpected: ${sourceHash}\nFound: ${computeHash}"
    fi
}

# Download a file from sources/
function downloadSource()
{
    [ ! -z "${1}" ] || serpentFail "Incorrect use of downloadSource"
    sourceFile="${SERPENT_SOURCES_DIR}/${1}"
    [ -f "${sourceFile}" ] || serpentFail "Missing source file: ${sourceFile}"
    sourceURL="$(cat ${sourceFile} | cut -d ' ' -f 1)"
    sourceHash="$(cat ${sourceFile} | cut -d ' ' -f 2)"
    [ ! -z "${sourceURL}" ] || serpentFail "Missing URL for source: $1"
    [ ! -z "${sourceHash}" ] || serpentFail "Missing hash for source: $1"
    sourcePathBase=$(basename "${sourceURL}")
    sourcePath="${SERPENT_DOWNLOAD_DIR}/${sourcePathBase}"

    mkdir -p "${SERPENT_DOWNLOAD_DIR}" || serpentFail "Failed to create download tree"

    if [[ -f "${sourcePath}" ]]; then
        printInfo "Skipping download of ${sourcePathBase}"
        verifyDownload "${1}"
        return
    fi

    if [[ -f "${sourcePath}.partial" ]]; then
        printInfo "Resuming download of ${sourcePathBase}"
        curl -C - -L --fail --ftp-pasv --retry 3 --retry-delay 5 -o "${sourcePath}.partial" "${sourceURL}"
        mv "${sourcePath}.partial" "${sourcePath}" || serpentFail "Failed to move completed resumed file"
        verifyDownload "${1}"
        return
    fi

    printInfo "Downloading ${sourcePathBase}"
    curl -C - -L --fail --ftp-pasv --retry 3 --retry-delay 5 -o "${sourcePath}.partial" "${sourceURL}"
    mv "${sourcePath}.partial" "${sourcePath}" || serpentFail "Failed to move completed downloaded file"
    verifyDownload "${1}"
}

# Extract a tarball into the current working directory
function extractSource()
{
    [ ! -z "${1}" ] || serpentFail "Incorrect use of extractSource"
    sourceFile="${SERPENT_SOURCES_DIR}/${1}"
    [ -f "${sourceFile}" ] || serpentFail "Missing source file: ${sourceFile}"
    sourceURL="$(cat ${sourceFile} | cut -d ' ' -f 1)"
    [ ! -z "${sourceURL}" ] || serpentFail "Missing URL for source: $1"
    sourcePathBase=$(basename "${sourceURL}")
    sourcePath="${SERPENT_DOWNLOAD_DIR}/${sourcePathBase}"

    printInfo "Extracting ${sourcePathBase}"

    tar xf "${sourcePath}" -C . || serpentFail "Failed to extract ${sourcePath}"
}

# Prepare the build tree
function prepareBuild()
{
    export SERPENT_BUILD_DIR="${SERPENT_BUILD_DIR}/${SERPENT_BUILD_NAME}"
    printInfo "Building ${SERPENT_BUILD_NAME} in ${SERPENT_BUILD_DIR}"

    if [[ -d "${SERPENT_BUILD_DIR}" ]]; then
        printWarning "Removing stale build directory"
        rm -rf "${SERPENT_BUILD_DIR}" || serpentFail "Failed to remove stale build directory"
    fi

    mkdir -p "${SERPENT_BUILD_DIR}" || serpentFail "Cannot create working tree"
    cd "${SERPENT_BUILD_DIR}"
}

# Fetch all sources for all builds
function prefetchSources()
{
    printInfo "Prefetching all sources"

    for sourceFile in "${SERPENT_SOURCES_DIR}"/* ; do
        bnom=$(basename "${sourceFile}")
        downloadSource "${bnom}"
    done
}

# Activate the stage1 compiler for use.
function activateStage1Compiler()
{
    export SERPENT_STAGE1_TREE=$(getInstallDir "1")

    if [[ ! -e "${SERPENT_STAGE1_TREE}/usr/bin/clang" ]]; then
        printError "No stage1 compiler found"
        exit 1
    fi

    export PATH="${SERPENT_STAGE1_TREE}/usr/bin:$PATH"

    # Check its the right clang/llvm.
    SERPENT_LLVM_TARGET=$(llvm-config --host-target)
    if [[ $? -ne 0 ]]; then
        printError "Could not run llvm-config"
        exit 1
    fi

    if [[ "${SERPENT_LLVM_TARGET}" != "${SERPENT_TRIPLET}" ]]; then
        printError "Incorrect LLVM target: ${SERPENT_LLVM_TARGET}"
        exit 1
    fi

    printInfo "Using clang/llvm target: ${SERPENT_LLVM_TARGET}"

    unset SERPENT_LLVM_TARGET

    export CC="clang"
    export CXX="clang++"
    export AR="llvm-ar"
    export NM="llvm-nm"
    export OBJDUMP="llvm-objdump"
    export RANLIB="llvm-ranlib"
    export READELF="llvm-readelf"
    export STRIP="llvm-strip"

    # Handle libc specifics for stage1
    if [[ "${SERPENT_LIBC}" == "musl" ]]; then
        export SERPENT_LIBC_FLAGS="-D_LIBCPP_HAS_MUSL_LIBC"
    else
        export SERPENT_LIBC_FLAGS=""
    fi

    export CFLAGS="${SERPENT_TARGET_CFLAGS} -I${SERPENT_INSTALL_DIR}/usr/include -L${SERPENT_STAGE1_TREE}/lib -L${SERPENT_INSTALL_DIR}/usr/lib -Wno-unused-command-line-argument ${SERPENT_LIBC_FLAGS} -Wno-error"
    export CXXFLAGS="${SERPENT_TARGET_CXXFLAGS} -I${SERPENT_INSTALL_DIR}/usr/include -L${SERPENT_STAGE1_TREE}/lib -L${SERPENT_INSTALL_DIR}/usr/lib -Wno-unused-command-line-argument ${SERPENT_LIBC_FLAGS} -Wno-error"
    export LDFLAGS="${SERPENT_TARGET_LDFLAGS} -L${SERPENT_STAGE1_TREE}/lib -L${SERPENT_INSTALL_DIR}/usr/lib"
    export PKG_CONFIG_PATH="${SERPENT_INSTALL_DIR}/usr/lib/pkgconfig:${SERPENT_INSTALL_DIR}/usr/share/pkgconfig"

    unset SERPENT_STAGE1_TREE
}


# Basic validation.
[ -d "${SERPENT_SOURCES_DIR}" ] || serpentFail "Missing source tree"

# Check basic requirements before we go anywhere.
requireTools autoreconf autopoint bison cmake curl gcc g++ ninja patch tar uname

# TODO: Revisit this if needed
export SERPENT_ARCH=$(uname -m)

if [[ -e '/lib/ld-linux-x86-64.so.2' ]] || [[ -e '/lib64/ld-linux-x86-64.so.2' ]]; then
    export SERPENT_HOST="${SERPENT_ARCH}-linux-gnu"
else
    printError "Unsupported host configuration"
    exit 1
fi

[ -e "${SERPENT_ROOT_DIR}/targets/${SERPENT_TARGET}.sh" ] || serpentFail "Failed to load targets/${SERPENT_TARGET}.sh"

unset CFLAGS
unset CXXFLAGS
unset LDFLAGS

printInfo "Using '${SERPENT_TARGET}' build configuration"
source "${SERPENT_ROOT_DIR}/targets/${SERPENT_TARGET}.sh"
