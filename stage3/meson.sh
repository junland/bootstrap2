#!/bin/true
set -e

. $(dirname $(realpath -s $0))/common.sh

extractSource meson
serpentChrootCd meson-*


printInfo "Building meson"
serpentChroot python3 setup.py build

printInfo "Installing meson"
serpentChroot python3 setup.py install
