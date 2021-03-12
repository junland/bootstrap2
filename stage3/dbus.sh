#!/bin/true
set -e

. $(dirname $(realpath -s $0))/common.sh

extractSource dbus
serpentChrootCd dbus-*


printInfo "Configuring dbus"

serpentChroot ./configure \
    --build="${SERPENT_TRIPLET}" \
    --host="${SERPENT_TRIPLET}" \
    --prefix=/usr \
    --sysconfdir=/etc \
    --libdir=/usr/lib \
    --bindir=/usr/bin \
    --sbindir=/usr/sbin \
    --datadir=/usr/share \


printInfo "Building dbus"
serpentChroot make -j "${SERPENT_BUILD_JOBS}"

printInfo "Installing dbus"
serpentChroot make -j "${SERPENT_BUILD_JOBS}" install

# Clean up unwanted files
rm "${SERPENT_INSTALL_DIR}/usr/bin/dbus-daemon"
rm "${SERPENT_INSTALL_DIR}/usr/lib/systemd/system/dbus.service"
rm "${SERPENT_INSTALL_DIR}/usr/lib/systemd/system/dbus.socket"
rm "${SERPENT_INSTALL_DIR}/usr/lib/systemd/system/sockets.target.wants/dbus.socket"
rm "${SERPENT_INSTALL_DIR}/usr/lib/systemd/system/multi-user.target.wants/dbus.service"
