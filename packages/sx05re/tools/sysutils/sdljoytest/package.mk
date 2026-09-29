# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2020-present Shanti Gilbert (https://github.com/shantigilbert)

PKG_NAME="sdljoytest"
PKG_VERSION="2de7e7fa14e11059eda7061caa95f2130e3ae68d"
PKG_SHA256="9d556868ba7e8f5d0625178f91dc855a7033305abda627a012d7ce3711cca30a"
PKG_LICENSE="OSS"
PKG_SITE="https://github.com/luziellacerda/sdljoytest"
PKG_URL="${PKG_SITE}/archive/${PKG_VERSION}.tar.gz"
PKG_DEPENDS_TARGET="toolchain SDL2"
PKG_LONGDESC="Test joystick with SDL2 in Linux"
PKG_TOOLCHAIN="make"

pre_configure_target() {
sed -i -E "s|^([[:space:]]*)[^[:space:]]+ -g -o |\\1${CC} -g -o |" Makefile
}

makeinstall_target() {
mkdir -p ${INSTALL}/usr/bin
cp -rf test_gamepad_SDL2 ${INSTALL}/usr/bin/sdljoytest
cp -rf map_gamepad_SDL2 ${INSTALL}/usr/bin/sdljoymap
cp -rf gamepad_info ${INSTALL}/usr/bin/gamepad_info
cp -rf sdl_ra_joystick_map ${INSTALL}/usr/bin/sdl_ra_joystick_map
}
