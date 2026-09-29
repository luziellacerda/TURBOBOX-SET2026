# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2022-present 7Ji (https://github.com/7Ji)

PKG_NAME="turborama-32bit-info"
PKG_VERSION="1"
PKG_ARCH="aarch64"
PKG_LICENSE="GPLv2"
PKG_SITE="https://github.com/luziellacerda/turborama-32bit-libs"
PKG_URL=""
PKG_DEPENDS_TARGET="lib32-retroarch"
PKG_LONGDESC="Turborama 32-bit infos, stolen from turborama-32bit-libs, since I don't want to break that package"
PKG_TOOLCHAIN="manual"

unpack() {
  :
}

make_target() {
  :
}

makeinstall_target() {
  mkdir -p ${INSTALL}/usr/lib/libretro
  cp $(get_pkg_directory turborama-32bit-libs)/infos/*.info ${INSTALL}/usr/lib/libretro/
}