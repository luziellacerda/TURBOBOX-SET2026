# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2025-present EmuELEC (https://github.com/EmuELEC)

PKG_NAME="turborama-sysutils"
PKG_VERSION="v1"
PKG_LICENSE="Public Domain"
PKG_SITE="https://github.com/luziellacerda/TURBOBOX-SET2026"
PKG_DEPENDS_TARGET="toolchain"
PKG_SHORTDESC="Misc Turborama specific utils"
PKG_TOOLCHAIN="manual"

make_target() {
	mkdir -p bin
    ${CC} -O2 turborama-settings.c -o bin/turborama-settings
    ${CC} -O2 turborama_asd.c -o bin/turborama_asd
}

makeinstall_target() {
  mkdir -p ${INSTALL}/usr/bin
    cp bin/* ${INSTALL}/usr/bin
}
