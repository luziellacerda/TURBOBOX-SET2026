# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2020-present Shanti Gilbert (https://github.com/shantigilbert)

PKG_NAME="rs97-commander-sdl2"
PKG_VERSION="b83ef67f6e20bdd5af3276b5e6e8705109b400aa"
PKG_SHA256="cbf324cf0b3d56f88c3408683324b03ded8cbe1d8855efd4f9fdde2e23e73da0"
PKG_REV="1"
PKG_ARCH="any"
PKG_LICENSE="GPL"
PKG_SITE="https://github.com/luziellacerda/rs97-commander-sdl2"
PKG_URL="${PKG_SITE}/archive/${PKG_VERSION}.tar.gz"
PKG_DEPENDS_TARGET="toolchain SDL2 SDL2_image SDL2_gfx SDL2_ttf freetype"
PKG_SECTION="tools"
PKG_SHORTDESC="Two-pane commander for RetroFW and RG-350 (fork of Dingux Commander)"

pre_configure_target() {
sed -i "s|sdl2-config|${SYSROOT_PREFIX}/usr/bin/sdl2-config|" Makefile
sed -i "s|CC=g++|CC=${CXX}|" Makefile

OGA=0

if [[ "${DEVICE}" == "OdroidGoAdvance" || "${DEVICE}" == "GameForce" ]]; then
	OGA=1
fi

PKG_MAKE_OPTS_TARGET=" ODROIDGO=${OGA} CC=${CXX}"
	
}

makeinstall_target() {
  mkdir -p ${INSTALL}/usr/bin
  mkdir -p ${INSTALL}/usr/config/turborama/configs/fm
  cp DinguxCommander ${INSTALL}/usr/bin/
  cp -rf res ${INSTALL}/usr/config/turborama/configs/fm/
}
