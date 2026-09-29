# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2020-present Shanti Gilbert (https://github.com/shantigilbert)

PKG_NAME="Crystal"
PKG_VERSION="7c2304f663d7a7e682efbb6aa1fbcde6f3d4b7bc"
PKG_GIT_CLONE_BRANCH="Turborama"
PKG_REV="1"
PKG_ARCH="any"
PKG_LICENSE="GPL"
PKG_SITE="https://github.com/luziellacerda/es-theme-Turborama-crystal"
PKG_URL="${PKG_SITE}.git"
PKG_DEPENDS_TARGET="toolchain Crystal-Collections"
PKG_SECTION="turborama"
PKG_SHORTDESC="Crystal theme for TURBORAMA by Dim (dm2912)"
PKG_TOOLCHAIN="manual"
GET_HANDLER_SUPPORT="git"

make_target() {
  : not
}

makeinstall_target() {
  mkdir -p ${INSTALL}/usr/config/emulationstation/themes/Crystal
    cp -r * ${INSTALL}/usr/config/emulationstation/themes/Crystal
    rm -rf ${INSTALL}/usr/config/emulationstation/themes/Crystal/screens.png
}
