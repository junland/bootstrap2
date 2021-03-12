#!/bin/bash

echo "Setting up host..."

apt update -y && apt dist-upgrade -y

apt install sshpass rsync build-essential qemu qemu-user-static wget curl cmake ninja-build \
                    mtools liblzma-dev libelf-dev libssl-dev zlib1g-dev zlib1g xz-utils lzip file gettext \
                    pkg-config libarchive-tools m4 gawk bc expect bison flex elfutils \
                    texinfo python3 perl elfutils libtool autoconf automake autopoint autoconf-archive --no-install-recommends -y

apt autoremove -y && apt clean all -y && apt autoclean -y

rm -rfv /var/lib/apt/lists/* /tmp/* /var/tmp/* || true
