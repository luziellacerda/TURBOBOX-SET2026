# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2019-present Shanti Gilbert (https://github.com/shantigilbert)

PKG_NAME="es-theme-Turborama-carbon"
PKG_VERSION="381e539bd1d7e86d87e2ba679e95ddca6888ddd2"
PKG_SHA256="525610acdee982343ae25a61bf65a7c6326464f07b11d363e5d2354870688b16"
PKG_REV="1"
PKG_ARCH="any"
PKG_LICENSE="GPL"
PKG_SITE="https://github.com/luziellacerda/es-theme-Turborama-carbon"
PKG_URL="${PKG_SITE}/archive/${PKG_VERSION}.tar.gz"
PKG_DEPENDS_TARGET="toolchain"
PKG_SECTION="turborama"
PKG_SHORTDESC="The EmulationStation theme Carbon Fabrice Caruso's fork with changes for Turborama by drixplm"
PKG_IS_ADDON="no"
PKG_AUTORECONF="no"
PKG_TOOLCHAIN="manual"

make_target() {
  : not
}

makeinstall_target() {
  mkdir -p ${INSTALL}/usr/config/emulationstation/themes/es-theme-Turborama-carbon
    cp -r * ${INSTALL}/usr/config/emulationstation/themes/es-theme-Turborama-carbon
}
