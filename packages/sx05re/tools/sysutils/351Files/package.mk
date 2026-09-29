# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2021-present Shanti Gilbert (https://github.com/shantigilbert)

PKG_NAME="351Files"
PKG_VERSION="2fa3f9ff8e50fb9b897fbc667affabd4ece004e7"
PKG_SHA256="2fa6c50521f01498651a6f1a74452de6c539ec3b126d56d25ef773d3483d95b6"
PKG_ARCH="any"
PKG_LICENSE="GPL"
PKG_SITE="https://github.com/luziellacerda/351Files"
PKG_URL="${PKG_SITE}/archive/${PKG_VERSION}.tar.gz"
PKG_DEPENDS_TARGET="toolchain SDL2 SDL2_image SDL2_gfx SDL2_ttf freetype file"
PKG_LONGDESC="File Manager"
PKG_TOOLCHAIN="make"

pre_configure_target() {
  sed -i "s|ifeq (\$(DEVICE),PC)||g" Makefile
  sed -i "s|endif||g" Makefile
  sed -i "s|START_PATH = \$(PWD)||g" Makefile
  sed -i "s|sdl2-config|${SYSROOT_PREFIX}/usr/bin/sdl2-config|g" Makefile
  sed -i "s|g++|\$(CXX)|g" Makefile

	TURBORAMA_DEVICE_VARIANT="PC"

if [ "${DEVICE}" == "OdroidGoAdvance" ] || [ "${DEVICE}" == "GameForce" ]; then
	TURBORAMA_DEVICE_VARIANT="TURBORAMA_HH"
fi

  PKG_MAKE_OPTS_TARGET=" START_PATH="/storage" DEVICE=${TURBORAMA_DEVICE_VARIANT} RES_PATH="/turborama/configs/fm/res""
}



makeinstall_target() {
  mkdir -p ${INSTALL}/usr/bin
  mkdir -p ${INSTALL}/usr/config/turborama/configs/fm
  cp 351Files ${INSTALL}/usr/bin/
  cp -rf res ${INSTALL}/usr/config/turborama/configs/fm/
  
  cp -rf ${PKG_DIR}/config/* ${INSTALL}/usr/config/turborama/configs/
  
  
}
