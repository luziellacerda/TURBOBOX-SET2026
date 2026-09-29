# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2019-present Shanti Gilbert (https://github.com/shantigilbert)

PKG_NAME="jslisten"
PKG_VERSION="b7f85c2573baaa49580104fade2af96d34f3546b"
PKG_SHA256="550f7d47d19455ad489860f5fb0888891953aa8ee227d8601cf3117635c6d5ee"
PKG_LICENSE="GPL3"
PKG_SITE="https://github.com/luziellacerda/turborama-jslisten"
PKG_URL="${PKG_SITE}/archive/${PKG_VERSION}.tar.gz"
PKG_DEPENDS_TARGET="toolchain systemd"
PKG_LONGDESC="listen to gamepad inputs and trigger a command, cloned from https://github.com/workinghard/jslisten"
PKG_TOOLCHAIN="make"

make_target() {
mkdir bin
make 
}

makeinstall_target() {
mkdir -p ${INSTALL}/usr/bin
cp bin/jslisten ${INSTALL}/usr/bin
} 
