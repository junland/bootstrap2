#/usr/bin/env -S -i bash --norc --noprofile

set -e

msg() {
  echo -e "\e[39m >>> $1 \e[0m"
}

msg_fail() {
  echo -e "\e[31m >>> $1 \e[0m"
  exit 1
}

msg_fail_stage3_term() {
  term_mount_dirs_stage3
  echo -e "\e[31m >>> $1 \e[0m"
  exit 1
}

check_target() {
    [ -f "${STRAP_TARGETS_DIR}/${STRAP_SELECTED_TARGET}.tgt" ] || msg_fail "Failed to find target file for ${STRAP_SELECTED_TARGET}"
}

download_sources() {
    [ ! -z "${STRAP_SOURCES_DIR}" ] || msg_fail "download_sources: Sources directory not set."
    [ ! -z "${STRAP_ROOT_DIR}" ] || msg_fail "download_sources: Root directory not set."
    
    msg "Downloading sources..."
    while read -r url; do
       cd $STRAP_SOURCES_DIR

       file=${url##*/}

       if [[ -f "${STRAP_SOURCES_DIR}/$file" ]]; then
        msg "File exists, skipping download of ${file}"
        continue
       fi

       msg "Downloading $url"
       curl -C - -L --fail --ftp-pasv --retry 3 --retry-delay 5 -o $STRAP_SOURCES_DIR/${file} "${url}" || msg_fail "Failed to download file: ${line}"
    done < $STRAP_SOURCES_DIR/SOURCES.list

    cd $STRAP_ROOT_DIR
}

setup_dirs_stage1() {
    [ ! -z "${STRAP_STAGE1_INSTALL_DIR}" ] || msg_fail "setup_dirs_stage1: stage1 install directory not set."
    [ ! -z "${STRAP_BUILD_DIR}" ] || msg_fail "setup_dirs_stage1: Build directory not set."
    [ ! -z "${STRAP_ROOT_DIR}" ] || msg_fail "setup_dirs_stage1: Root directory not set."

    msg "Setting up directory structure for stage1..."
    mkdir -p $STRAP_STAGE1_INSTALL_DIR
    mkdir -p $STRAP_BUILD_DIR

    msg "Setting stage1 step permissions..."
    chmod +x -R ${STRAP_ROOT_DIR}/stage1/*.step
}

setup_dirs_stage2() {
    [ ! -z "${STRAP_STAGE2_INSTALL_DIR}" ] || msg_fail "setup_dirs_stage2: stage2 install directory not set."
    [ ! -z "${STRAP_BUILD_DIR}" ] || msg_fail "setup_dirs_stage2: Build directory not set."
    [ ! -z "${STRAP_ROOT_DIR}" ] || msg_fail "setup_dirs_stage2: Root directory not set."

    msg "Setting up directory structure for stage2..."
    mkdir -p $STRAP_STAGE2_INSTALL_DIR
    mkdir -p $STRAP_BUILD_DIR

    msg "Setting stage2 step permissions..."
    chmod +x -R ${STRAP_ROOT_DIR}/stage2/*.step
}

setup_dirs_stage3() {
    [ ! -z "${STRAP_STAGE3_INSTALL_DIR}" ] || msg_fail "setup_dirs_stage3: stage3 install directory not set."
    [ ! -z "${STRAP_BUILD_DIR}" ] || msg_fail "setup_dirs_stage3: Build directory not set."
    [ ! -z "${STRAP_ROOT_DIR}" ] || msg_fail "setup_dirs_stage3: Root directory not set."

    msg "Setting up directory structure for stage3..."
    mkdir -p $STRAP_STAGE3_INSTALL_DIR
    mkdir -p $STRAP_BUILD_DIR

    msg "Setting stage3 step permissions..."
    chmod +x -R ${STRAP_ROOT_DIR}/stage3/*.step
}

clean_build_dir() {
    [ ! -z "${STRAP_BUILD_DIR}" ] || msg_fail "clean_build_dir: Build directory not set."

    msg "Cleaning previous build directory..."
    rm -rf $STRAP_BUILD_DIR
    mkdir -p $STRAP_BUILD_DIR

    if [ -f "${STRAP_STAGE3_INSTALL_DIR}/build" ]; then
      msg "Also cleaning up stage3 build directory..."
      rm -rf "${STRAP_STAGE3_INSTALL_DIR}/build"
    fi
}

extract_source_pkg() {
    [ ! -z "${1}" ] || msg_fail "extract_source_pkg: Source package not set."
    [ ! -z "${STRAP_BUILD_DIR}" ] || msg_fail "extract_source_pkg: Build directory not set."
    [ ! -z "${STRAP_SOURCES_DIR}" ] || msg_fail "extract_source_pkg: Sources directory not set."

    msg "Extracting $1 into $STRAP_BUILD_DIR ..."
    tar -xf "$STRAP_SOURCES_DIR"/$1-* -C $STRAP_BUILD_DIR
    
    msg "Linking for easy access..."
    ln -sv $1-* $STRAP_BUILD_DIR/$1
}

export -f msg
export -f msg_fail
export -f check_target
export -f download_sources
export -f clean_build_dir
export -f extract_source_pkg
export -f setup_dirs_stage1
export -f setup_dirs_stage2
export -f msg_fail_stage3_term

setup_chroot_dirs_stage3() {
  [ ! -z "${1}" ] || msg_fail "setup_chroot_dirs_stage3: Target directory not set."

  msg "Creating stage3 default directories..."
  install -D -d -m 00755 "${1}/build" || msg_fail "setup_chroot_dirs_stage3: Failed to create ${1}/build"

  msg "Creating stage3 mount directories..."
  install -D -d -m 00755 "${1}/dev/pts" || msg_fail "setup_chroot_dirs_stage3: Failed to create ${1}/dev/pts"
  install -D -d -m 00755 "${1}/proc" || msg_fail "setup_chroot_dirs_stage3: Failed to create ${1}/proc"
  install -D -d -m 00755 "${1}/sys" || msg_fail "setup_chroot_dirs_stage3: Failed to create ${1}/sys"
  install -D -d -m 00755 "${1}/stage2" || msg_fail "setup_chroot_dirs_stage3: Failed to create ${1}/stage2"
}

init_mount_dirs_stage2() {
  [ ! -z "${STRAP_STAGE2_INSTALL_DIR}" ] || msg_fail "init_mount_dirs_stage2: Stage 2 directory not set."
  
  msg "Initializing directories for stage2 for chroot..."
  mount -v --bind /dev/pts "${STRAP_STAGE2_INSTALL_DIR}/dev/pts" || msg_fail "init_mount_dirs_stage2: Failed to bind-mount /dev/pts"
  mount -v --bind /sys "${STRAP_STAGE2_INSTALL_DIR}/sys" || msg_fail "init_mount_dirs_stage2: Failed to bind-mount /sys"
  mount -v --bind /proc "${STRAP_STAGE2_INSTALL_DIR}/proc" || msg_fail "init_mount_dirs_stage2: Failed to bind-mount /proc"
}

init_mount_dirs_stage3() {
  [ ! -z "${STRAP_STAGE2_INSTALL_DIR}" ] || msg_fail "init_mount_dirs_stage3: Stage 2 directory not set."
  [ ! -z "${STRAP_STAGE3_INSTALL_DIR}" ] || msg_fail "init_mount_dirs_stage3: Stage 3 directory not set."
  [ ! -z "${STRAP_BUILD_DIR}" ] || msg_fail "init_mount_dirs_stage3: Build directory not set."
  
  msg "Initializing directories for stage3 for chroot..."
  mount -v --bind /dev/pts "${STRAP_STAGE3_INSTALL_DIR}/dev/pts" || msg_fail "init_mount_dirs_stage3: Failed to bind-mount /dev/pts"
  mount -v --bind /sys "${STRAP_STAGE3_INSTALL_DIR}/sys" || msg_fail "init_mount_dirs_stage3: Failed to bind-mount /sys"
  mount -v --bind /proc "${STRAP_STAGE3_INSTALL_DIR}/proc" || msg_fail "init_mount_dirs_stage3: Failed to bind-mount /proc"
  
  mount -v --bind -o ro "${STRAP_STAGE2_INSTALL_DIR}" "${STRAP_STAGE3_INSTALL_DIR}/stage2" || msg_fail "init_mount_dirs_stage3: Failed to bind-mount /stage2"
  mount -v -o remount,ro,bind "${STRAP_STAGE3_INSTALL_DIR}/stage2" || msg_fail "init_mount_dirs_stage3: Failed to make /stage2 read-only"
}

install_qemu_static() {
  [ ! -z "${1}" ] || msg_fail "install_qemu_static: Target directory not set."
  [ ! -z "${STRAP_QEMU_STATIC}" ] || msg_fail "install_qemu_static: QEMU static binary not set."
  
  msg "Installing qemu-user-static..."
  
  install -D -m 00755 $(which ${STRAP_QEMU_STATIC}) "${1}/usr/bin/${STRAP_QEMU_STATIC}" || msg_fail "install_qemu_static: Failed to install qemu-user-static"
}

run_cmd_chroot_stage3() {
  [ ! -z "${1}" ] || msg_fail "run_cmd_chroot_stage3: No command has been set to execute."

  for shell in "sh" "ash" "bash" "dash"; do
    msg "Searching for shell: $shell"
    if [ -f "$STRAP_STAGE2_INSTALL_DIR"/bin/$shell ] || [ -L "$STRAP_STAGE2_INSTALL_DIR"/bin/$shell ]; then
      msg "Selected $shell as the selected shell..."
      export CHROOT_SHELL=/stage2/usr/bin/$shell
      break
    fi
  done

  CHROOT_PATH=/bin:/usr/bin:/sbin:/usr/sbin

  CHROOT_CD=${CHROOT_CD:-"/"}

  LD_LIBRARY_PATH="/stage2/usr/lib" PATH="${CHROOT_PATH}:/stage2/usr/bin" chroot "${STRAP_STAGE3_INSTALL_DIR}" ${CHROOT_SHELL} -c "cd ${CHROOT_CD}; ${1}"
}

term_mount_dirs_stage3() {
  [ ! -z "${STRAP_STAGE3_INSTALL_DIR}" ] || msg_fail "term_mount_dirs_stage3: Stage 3 directory not set."
  
  for target in "stage2" "dev/pts" "sys" "proc"; do
    msg "Attempting to unmount ${target}"
    umount "${STRAP_STAGE3_INSTALL_DIR}/${target}"
    if [[ "$?" != 0 ]]; then
      sleep 1
      msg "Attempting to unmount ${target} again"
      umount "${STRAP_STAGE3_INSTALL_DIR}/${target}"
    fi
    if [[ "$?" != "0" ]]; then
        msg "Lazy-unmounting ${target}"
        umount -l "${STRAP_STAGE3_INSTALL_DIR}/${target}" || :
    fi
  done
}

copy_local_build_stage3() {
  [ ! -z "${STRAP_BUILD_DIR}" ] || msg_fail "copy_local_build_stage3: Build directory not set."
  [ ! -z "${STRAP_STAGE3_INSTALL_DIR}" ] || msg_fail "copy_local_build_stage3: Stage 3 directory not set."
  [ ! -f "${STRAP_STAGE3_INSTALL_DIR}/build" ] || msg_fail "copy_local_build_stage3: Stage 3 build directory does not exist."

  msg "Copying local build directory contents to stage3 build directory..."
  cp -r ${STRAP_BUILD_DIR}/* ${STRAP_STAGE3_INSTALL_DIR}/build
}

export -f setup_chroot_dirs_stage3
export -f init_mount_dirs_stage2
export -f init_mount_dirs_stage3
export -f install_qemu_static
export -f run_cmd_chroot_stage3
export -f term_mount_dirs_stage3
export -f copy_local_build_stage3
