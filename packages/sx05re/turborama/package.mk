# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2019-present Shanti Gilbert (https://github.com/shantigilbert)

PKG_NAME="turborama"
PKG_LICENSE="GPLv2"
PKG_SITE=""
PKG_URL=""
PKG_DEPENDS_TARGET="toolchain ${OPENGLES} turborama-emulationstation retroarch"
PKG_SECTION="turborama"
PKG_LONGDESC="Turborama Meta Package"
PKG_TOOLCHAIN="manual"

PKG_EXPERIMENTAL="nestopiaCV quasi88 xmil np2kai hypseus-singe yabasanshiroSA_1_11 yabasanshiroSA_1_5 fbneoSA same_cdi ikemen-go" 
PKG_EMUS="${LIBRETRO_CORES} desmume melonds advancemame PPSSPPSDL amiberry amiberry-lite hatarisa openbor dosbox-staging mupen64plus-nx mupen64plus-nx-alt scummvmsa stellasa solarus dosbox-pure pcsx_rearmed ecwolf potator freej2me duckstation flycastsa fmsx-libretro jzintv mupen64plussa xroar x16 simcoupe ti99sim oricutron eka2l1 bigpemu biginstinct memu openmsx openmsx-ld touchhle"

PKG_DEPENDS_TARGET+=" turborama-tools ${PKG_EMUS} ${PKG_EXPERIMENTAL}"


# These packages are only meant for S922x, S905x2 and A311D devices as they run poorly on S905" 
if [ "${DEVICE}" == "Amlogic-ng" ] || [ "${DEVICE}" == "Amlogic-no" ] || [ "${DEVICE}" == "RK356x" ] || [ "${DEVICE}" == "OdroidM1" ]; then
	PKG_DEPENDS_TARGET+=" ${LIBRETRO_S922X_CORES}"
fi

if [ "${DEVICE}" == "OdroidGoAdvance" ] || [ "${DEVICE}" == "GameForce" ]; then
	PKG_DEPENDS_TARGET+=" kmscon odroidgoa-utils"
    
  #we disable some cores that are not working or work poorly on OGA
	for discore in duckstation mesen-s virtualjaguar quicknes MC; do
		PKG_DEPENDS_TARGET=$(echo ${PKG_DEPENDS_TARGET} | sed "s|${discore} | |")
	done
	PKG_DEPENDS_TARGET+=" yabasanshiro"
else
	PKG_DEPENDS_TARGET+=" fbterm"
fi

# These cores do not work, or are not needed on aarch64, this package needs cleanup :) 
if [ "${ARCH}" == "aarch64" ]; then
  for discore in quicknes parallel-n64 pcsx_rearmed; do
		PKG_DEPENDS_TARGET=$(echo ${PKG_DEPENDS_TARGET} | sed "s|${discore}| |")
	done

  PKG_DEPENDS_TARGET+=" swanstation \
                        lib32-essential \
                        lib32-retroarch \
                        turborama-32bit-info \
                        lib32-flycast \
                        lib32-mupen64plus \
                        lib32-pcsx_rearmed \
                        lib32-uae4arm \
                        lib32-parallel-n64 \
                        lib32-bennugd-monolithic \
                        lib32-droidports \
                        lib32-box86 \
                        lib32-libusb"

  if [ "${DEVICE}" == "Amlogic-ng" ] || [ "${DEVICE}" == "Amlogic-no" ] || [ "${DEVICE}" == "RK356x" ] || [ "${DEVICE}" == "OdroidM1" ]; then
    PKG_DEPENDS_TARGET+=" dolphinSA"
  fi

  if [ "${DEVICE}" == "Amlogic-old" ]; then
    #we disable some cores that are not working or work poorly on Amlogic-old
    for discore in yabasanshiroSA_1_11 yabasanshiroSA_1_5 yabasanshiro same_cdi duckstation; do
      PKG_DEPENDS_TARGET=$(echo ${PKG_DEPENDS_TARGET} | sed "s|${discore} | |")
    done
  fi
fi

# We make sure MAME is the last Turborama package to be built.
if [ "${DEVICE}" == "Amlogic-ng" ] || [ "${DEVICE}" == "Amlogic-no" ] || [ "${DEVICE}" == "RK356x" ] || [ "${DEVICE}" == "OdroidM1" ]; then
	PKG_DEPENDS_TARGET+=" mame"
fi

# These packages do not yet compile for OdroidM1
if [ "${DEVICE}" == "RK356x" ] || [ "${DEVICE}" == "OdroidM1" ]; then
 for discore in flycast-dojo; do
		PKG_DEPENDS_TARGET=$(echo ${PKG_DEPENDS_TARGET} | sed "s|${discore}| |")
	done
fi

makeinstall_target() {

	mkdir -p ${INSTALL}/usr/bin
	cp -rf ${PKG_DIR}/bin ${INSTALL}/usr

	mkdir -p ${INSTALL}/usr/config/
  cp -rf ${PKG_DIR}/config/* ${INSTALL}/usr/config/
  ln -sf /storage/.config/turborama ${INSTALL}/turborama

  # Added for compatibility with portmaster
  ln -sf /storage/roms ${INSTALL}/roms
  ln -sf /storage/roms/ports/PortMaster ${INSTALL}/PortMaster
  mkdir -p ${INSTALL}/usr/bin/ports
  touch ${INSTALL}/usr/bin/ports/.ports_here

  find ${INSTALL}/usr/config/turborama/ -type f -exec chmod o+x {} \;

	mkdir -p ${INSTALL}/usr/config/turborama/logs
	ln -sf /var/log ${INSTALL}/usr/config/turborama/logs/var-log

  # leave for compatibility
  if [ "${DEVICE}" == "Amlogic-old" ]; then
    echo "s905" > ${INSTALL}/turborama_s905
  fi


  echo "${DEVICE}" > ${INSTALL}/turborama_arch
  
  mkdir -p ${INSTALL}/usr/share/retroarch-overlays
  cp -r ${PKG_DIR}/overlay/* ${INSTALL}/usr/share/retroarch-overlays
  
  mkdir -p ${INSTALL}/usr/share/common-shaders
  cp -r ${PKG_DIR}/shaders/* ${INSTALL}/usr/share/common-shaders
    
  mkdir -p ${INSTALL}/usr/share/libretro-database
  touch ${INSTALL}/usr/share/libretro-database/dummy
}

post_install() {
  for i in borders effects gamepads ipad keyboards misc; do
    rm -rf "${INSTALL}/usr/share/retroarch-overlays/${i}"
  done

  mkdir -p ${INSTALL}/etc/retroarch-joypad-autoconfig
  cp -r ${PKG_DIR}/gamepads/* ${INSTALL}/etc/retroarch-joypad-autoconfig

  # link default.target to turborama.target
  ln -sf turborama.target ${INSTALL}/usr/lib/systemd/system/default.target
  enable_service turborama-autostart.service
  enable_service turborama-disable_small_cores.service
  enable_service turborama-reboot.service
  enable_service turborama-shutdown.service


  # Remove scripts from OdroidGoAdvance build
  if [[ ${DEVICE} == "OdroidGoAdvance" || "${DEVICE}" == "GameForce" ]]; then 
    for i in "wifi" "sselphs_scraper" "skyscraper" "system_info"; do 
    xmlstarlet ed -L -P -d "/gameList/game[name='${i}']" ${INSTALL}/usr/bin/scripts/setup/gamelist.xml
    rm "${INSTALL}/usr/bin/scripts/setup/${i}.sh"
    done
  fi 

  # For automatic updates we use the buildate
	date +"%m%d%Y" > ${INSTALL}/usr/buildate
	
	ln -sf /storage/roms ${INSTALL}/roms
	
  # We make sure all files in /usr/bin are executables
	find ${INSTALL}/usr/bin -type f -exec chmod +x {} \;
} 
