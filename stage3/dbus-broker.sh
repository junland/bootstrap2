#!/bin/true
set -e

. $(dirname $(realpath -s $0))/common.sh

extractSource dbus-broker
serpentChrootCd dbus-broker-*


printInfo "Configuring dbus-broker"
serpentChroot meson --buildtype=plain build \
        --prefix=/usr \


printInfo "Building dbus-broker"
serpentChroot ninja -j "${SERPENT_BUILD_JOBS}" -C build

printInfo "Installing dbus-broker"
serpentChroot ninja install -j "${SERPENT_BUILD_JOBS}" -C build

# Make dbus-broker the default
ln -svf ../dbus-broker.service "${SERPENT_INSTALL_DIR}/usr/lib/systemd/system/multi-user.target.wants/dbus-broker.service"
