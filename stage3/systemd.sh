#!/bin/true
set -e

. $(dirname $(realpath -s $0))/common.sh

extractSource systemd
serpentChrootCd systemd-*

pushd systemd-*

# Testing / not upstreamed
# Use net/if_arp.h NOT linux/if_arp.h
# When including linux/if_ether.h, include netinet/if_ether.h first

if [[ "${SERPENT_LIBC}" == "musl" ]]; then
    patch -p1 < "${SERPENT_PATCHES_DIR}/systemd/in-progress.patch"
    patch -p1 < "${SERPENT_PATCHES_DIR}/systemd/includes.patch"
    printInfo "Enabling libwildebeest workarounds"
    # If we don't enable __UAPI_DEF_ETHDR=0 then the private if_ether header gets used and breaks the world.
    export CFLAGS="${CFLAGS} $(serpentChroot pkg-config --cflags --libs libwildebeest) -Wno-unused-command-line-argument -D__UAPI_DEF_ETHHDR=0"
fi

printInfo "Configuring systemd"
serpentChroot meson --buildtype=plain build \
        --prefix=/usr \
        -Dtests=false \
        -Dfuzz-tests=false \
        -Dslow-tests=false \
        -Dinstall-tests=false \

printInfo "Building systemd"
serpentChroot ninja -j "${SERPENT_BUILD_JOBS}" -C build

printInfo "Installing systemd"
serpentChroot ninja install -j "${SERPENT_BUILD_JOBS}" -C build
