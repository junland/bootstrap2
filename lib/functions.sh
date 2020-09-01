#/usr/bin/env -S -i bash --norc --noprofile

set -e

msg() {
  echo -e "\e[39m >>> $1 \e[0m"
}

msg_fail() {
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

clean_build_dir() {
    [ ! -z "${STRAP_BUILD_DIR}" ] || msg_fail "clean_build_dir: Build directory not set."

    msg "Cleaning previous build directory..."
    rm -rf $STRAP_BUILD_DIR
    mkdir -p $STRAP_BUILD_DIR
}

extract_source_pkg() {
    [ ! -z "${1}" ] || msg_fail "extract_source_pkg: Source package not set."
    [ ! -z "${STRAP_BUILD_DIR}" ] || msg_fail "extract_source_pkg: Build directory not set."
    [ ! -z "${STRAP_SOURCES_DIR}" ] || msg_fail "extract_source_pkg: Sources directory not set."

    msg "Extracting $1 into $STRAP_BUILD_DIR ..."
    tar -xf "$STRAP_SOURCES_DIR"/$1-* -C $STRAP_BUILD_DIR
}

export -f msg
export -f msg_fail
export -f check_target
export -f download_sources
export -f clean_build_dir
export -f extract_source_pkg
export -f setup_dirs_stage1
export -f setup_dirs_stage2


mount_chroot() {
  msg "Creating file system directories..."
  
  mkdir -pv "$STRAP_ROOTFS"/{dev,proc,sys,run}

  msg "Mounting chroot..."
  
  mount -v --bind /dev "$STRAP_ROOTFS"/dev
  mount -vt devpts devpts "$STRAP_ROOTFS"/dev/pts -o gid=5,mode=620
  mount -vt proc proc "$STRAP_ROOTFS"/proc
  mount -vt sysfs sysfs "$STRAP_ROOTFS"/sys
  mount -vt tmpfs tmpfs "$STRAP_ROOTFS"/run

  msg "Done mounting chroot."
}

umount_chroot() {
  msg "Unmounting chroot..."

  umount -v "$STRAP_ROOTFS"/dev/pts
  umount -v "$STRAP_ROOTFS"/dev
  umount -v "$STRAP_ROOTFS"/run
  umount -v "$STRAP_ROOTFS"/proc
  umount -v "$STRAP_ROOTFS"/sys

  msg "Done unmounting chroot."
}

proot_run_cmd_tools() {
  ROOTFS_DIR=$1
  ROOTFS_DIR_ARCH=$(echo "$2" | cut -d "-" -f1)
  ROOTFS_CMD=$3
  
  for shell in "sh" "ash" "bash"; do
    msg "Searching for shell: $shell"
    if [ -f "$STRAP_ROOTFS"/bin/$shell ] || [ -L "$STRAP_ROOTFS"/bin/$shell ]; then
      msg "Selected $shell as rootfs shell..."
      export ROOTFS_SHELL=/bin/$shell
      break
    fi
  done

  if [ ! -f "/usr/bin/qemu-$(echo "$ROOTFS_DIR_ARCH" | cut -d "-" -f1)-static" ]; then
    msg "qemu static binary for $ROOTFS_DIR_ARCH does not exist."
    exit 1
  fi

  mount_chroot

  msg "Executing '$ROOTFS_CMD' command..."

  proot --cwd=/ -r "$ROOTFS_DIR" -q qemu-"$ROOTFS_DIR_ARCH"-static /usr/bin/env -i \
        HOME=/ TERM="$TERM" \
        LC_ALL=POSIX \
        PS1='(chroot)$ ' \
        PATH=/bin:/usr/bin:/sbin:/usr/sbin \
        $ROOTFS_SHELL -c "$ROOTFS_CMD ; echo $? > /.exit-code.out"

  umount_chroot

  SIG_NUM=$(cat $ROOTFS_DIR/.exit-code.out)

  msg "Here is the exit code..."

  cat $ROOTFS_DIR/.exit-code.out

  if [ $SIG_NUM != "0" ]; then
     msg "Something went wrong with executing proot_run_cmd_tools..."
     exit "$SIG_NUM"
  fi

  return
}

export -f mount_chroot
export -f umount_chroot
export -f proot_run_cmd_tools