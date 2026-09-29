# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2019-present Shanti Gilbert (https://github.com/shantigilbert)

PKG_NAME="advancemame"
PKG_VERSION="6a34ec0ec3fd74535ae559304ceb6c7ce63acff5"
PKG_SHA256="d6211711e1e46a3b3bae9bcf4bb8491c90cfc84e104044b6f18eb118fa0e7cf2"
PKG_REV="1"
PKG_ARCH="any"
PKG_LICENSE="MAME"
PKG_SITE="https://github.com/amadvance/advancemame"
PKG_URL="https://github.com/amadvance/advancemame/archive/${PKG_VERSION}.tar.gz"
PKG_SOURCE_DIR="advancemame-${PKG_VERSION}*"
PKG_DEPENDS_TARGET="toolchain freetype slang alsa SDL2"
PKG_SECTION="turborama/mod"
PKG_SHORTDESC="A MAME and MESS port with an advanced video support for Arcade Monitors, TVs, and PC Monitors "
PKG_LONGDESC="A MAME and MESS port with an advanced video support for Arcade Monitors, TVs, and PC Monitors "
PKG_IS_ADDON="no"
PKG_AUTORECONF="yes"
PKG_TOOLCHAIN="make"
PKG_BUILD_FLAGS="-parallel"

pre_configure_target() {
export CFLAGS=`echo ${CFLAGS} | sed -e "s|-O.|-O3|g"`
sed -i "s|#include <slang.h>|#include <${SYSROOT_PREFIX}/usr/include/slang.h>|" ${PKG_BUILD}/configure.ac
}

pre_make_target() {
VERSION="Turborama-v$(cat ${ROOT}/packages/sx05re/turborama/config/TURBORAMA_VERSION)-${PKG_VERSION:0:7}"
echo ${VERSION} > ${PKG_BUILD}/.version
}

make_target() {
cd ${PKG_BUILD}
./autogen.sh
./configure --prefix=/usr --datadir=/usr/share/ --datarootdir=/usr/share/ --host=${TARGET_NAME} --enable-fb --enable-freetype --with-freetype-prefix=${SYSROOT_PREFIX}/usr/ --enable-slang
make mame
make j
}

makeinstall_target() {
mkdir -p ${INSTALL}/usr/config/turborama/configs/advmame
mkdir -p ${INSTALL}/usr/bin

if [ "${DEVICE}" == "OdroidGoAdvance" ]; then
   cp -r ${PKG_DIR}/config/advmame.rc_oga ${INSTALL}/usr/config/turborama/configs/advmame/advmame.rc
elif [ "${DEVICE}" == "GameForce" ]; then
   cp -r ${PKG_DIR}/config/advmame.rc_gf ${INSTALL}/usr/config/turborama/configs/advmame/advmame.rc
else
   cp -r ${PKG_DIR}/config/advmame.rc ${INSTALL}/usr/config/turborama/configs/advmame/advmame.rc
fi

cp -r ${PKG_DIR}/bin/* ${INSTALL}/usr/bin
chmod +x ${INSTALL}/usr/bin/*

cp -r ${PKG_BUILD}/obj/mame/linux/blend/advmame ${INSTALL}/usr/bin
cp -r ${PKG_BUILD}/obj/j/linux/blend/advj ${INSTALL}/usr/bin
cp -r ${PKG_BUILD}/support/category.ini ${INSTALL}/usr/config/turborama/configs/advmame
cp -r ${PKG_BUILD}/support/sysinfo.dat ${INSTALL}/usr/config/turborama/configs/advmame
cp -r ${PKG_BUILD}/support/history.dat ${INSTALL}/usr/config/turborama/configs/advmame
cp -r ${PKG_BUILD}/support/hiscore.dat ${INSTALL}/usr/config/turborama/configs/advmame
cp -r ${PKG_BUILD}/support/event.dat ${INSTALL}/usr/config/turborama/configs/advmame
}
