# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2021-present Shanti Gilbert (https://github.com/shantigilbert)

PKG_NAME="jzintv"
PKG_VERSION="20200712"
PKG_LICENSE="FOSS"
PKG_SITE="http://spatula-city.org/~im14u2c/intv"
PKG_URL="${PKG_SITE}/dl/jzintv-${PKG_VERSION}-src.zip"
PKG_DEPENDS_TARGET="toolchain SDL2 SDL2_mixer SDL2_net"
PKG_LONGDESC="Joe Zbiciak Intellivision Emulator"
PKG_TOOLCHAIN="make"

pre_configure_target() {
sed -i "s|^SDL2_CFLAGS :=.*|SDL2_CFLAGS := \$(shell ${SYSROOT_PREFIX}/usr/bin/sdl2-config --cflags) -DUSE_SDL2|" src/Makefile
sed -i "s|^SDL2_LFLAGS :=.*|SDL2_LFLAGS := \$(shell ${SYSROOT_PREFIX}/usr/bin/sdl2-config --libs)|" src/Makefile
PKG_MAKE_OPTS_TARGET="-C src/ -f Makefile GNU_READLINE=0 "
}

makeinstall_target() {
  mkdir -p ${INSTALL}/usr/bin
  cp bin/jzintv ${INSTALL}/usr/bin
  cp ${PKG_DIR}/scripts/* ${INSTALL}/usr/bin
  
  mkdir -p ${INSTALL}/usr/config/turborama/configs
  cp -rf ${PKG_DIR}/config/* ${INSTALL}/usr/config/turborama/configs
}
