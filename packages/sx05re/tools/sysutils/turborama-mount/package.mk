# SPDX-License-Identifier: GPL-3.0
# Copyright (C) 2022-present 7Ji (https://github.com/7Ji)

PKG_NAME="turborama-mount"
PKG_VERSION="583b1dd78da10793fcbf31f5da048f93cefe0dfd"
PKG_SHA256="31b4f7fbced7750a07fc9a4c537523a32897e742aa17fac63e0127fa3f447efc"
PKG_SITE="https://github.com/luziellacerda/turborama-mount"
PKG_URL="${PKG_SITE}/archive/${PKG_VERSION}.tar.gz"
PKG_DEPENDS_TARGET="toolchain systemd"
PKG_LONGDESC="Multi-source ROMs mounting utility for Turborama"
PKG_TOOLCHAIN="make"
PKG_MAKE_OPTS_TARGET="LOGGING_ALL_TO_STDOUT=1"
