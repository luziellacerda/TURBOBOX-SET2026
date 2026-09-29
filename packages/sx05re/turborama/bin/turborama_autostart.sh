#!/bin/bash

# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2021-present Shanti Gilbert (https://github.com/shantigilbert)

# Source predefined functions and variables
. /etc/profile

# DO NOT modify this file, if you need to use autostart please use /storage/.config/custom_start.sh 

# It seems some slow SDcards have a problem creating the symlink on time :/
CONFIG_DIR="/storage/.emulationstation"
CONFIG_DIR2="/storage/.config/emulationstation"

if [ ! -L "${CONFIG_DIR}" ]; then
ln -sf ${CONFIG_DIR2} ${CONFIG_DIR}
fi

if [ "${TURBORAMA_DEVICE}" == "Amlogic" ]; then
    rm "/storage/.config/asound.conf" > /dev/null 2>&1
    cp "/storage/.config/asound.conf-amlogic" "/storage/.config/asound.conf"
    if [ "$(get_turborama_setting bool StopMusicOnScreenSaver)" != "false" ]; then 
        sed -i "/<bool name=\"StopMusicOnScreenSaver\"/d" "${ES_CONF}"
        sed -i "s|</config>|    <bool name=\"StopMusicOnScreenSaver\" value=\"false\" />\n</config>|g" "${ES_CONF}"
    fi
elif [ "${TURBORAMA_DEVICE}" == "Amlogic-ng" ] || [ "${TURBORAMA_DEVICE}" == "OdroidM1" ]; then
    rm "/storage/.config/asound.conf" > /dev/null 2>&1
    cp "/storage/.config/asound.conf-amlogic-ng" "/storage/.config/asound.conf"
elif [ "${TURBORAMA_DEVICE}" == "Amlogic-no" ]; then
    rm "/storage/.config/asound.conf" > /dev/null 2>&1
    cp "/storage/.config/asound.conf-amlogic-ng" "/storage/.config/asound.conf"
    
    AUDIO_DEVICE_NO=$(get_turborama_setting turborama_audio_device)
    if [ "${AUDIO_DEVICE_NO,,}" = "auto" ] || [ -z "${AUDIO_DEVICE_NO}" ]; then
    set_turborama_setting "turborama_audio_device" "0,2"
    fi
fi

HOSTNAME=$(get_turborama_setting system.hostname)
if [ ! -z "${HOSTNAME}" ];then 
    echo "${HOSTNAME}" > /storage/.cache/hostname
else
    echo "TURBORAMA" > /storage/.cache/hostname
fi
cat /storage/.cache/hostname > /proc/sys/kernel/hostname

if [[ "${TURBORAMA_DEVICE}" == "GameForce" ]]; then
LED=$(get_turborama_setting bl_rgb)
[ -z "${LED}" ] && LED="Off"
odroidgoa_utils.sh bl "${LED}"

LED=$(get_turborama_setting gf_statusled)
[ -z "${LED}" ] && LED="heartbeat"
odroidgoa_utils.sh pl "${LED}"


rk_wifi_init /dev/ttyS1
fi

if [[ "${TURBORAMA_DEVICE}" == "GameForce" ]] || [[ "${TURBORAMA_DEVICE}" == "OdroidGoAdvance" ]]; then
    if [ -e "/flash/no_oc.oga" ]; then 
        set_turborama_setting turborama_oga_oc disable
        OGAOC=""
    else
        OGAOC=$(get_turborama_setting turborama_oga_oc)
    fi
[ -z "${OGAOC}" ] && OGAOC="Off"
    odroidgoa_utils.sh oga_oc "${OGAOC}"
fi

# Mounts /storage/roms
MOUNT_HANDLER=$(get_turborama_setting turborama_mount.handler)
if [ -z "${MOUNT_HANDLER}" ]; then
  MOUNT_HANDLER="turborama-mount"
fi
${MOUNT_HANDLER} &> /turborama/logs/turborama-mount.log

# copy default bezel to /storage/roms/bezel if it doesn't exists
if [ ! -f "/storage/roms/bezels/default.cfg" ]; then 
mkdir -p /storage/roms/bezels/
cp -rf /usr/share/retroarch-overlays/bezels/* /storage/roms/bezels/ &
fi

# Restore config if backup exists
BACKUPTAR="turborama_backup_config.tar.gz"
BACKUPFILE="/storage/roms/backup/${BACKUPTAR}"

[[ ! -f "${BACKUPFILE}" ]] && BACKUPFILE="/var/media/TURBOROMS/backup/${BACKUPTAR}"

if [ -f "${BACKUPFILE}" ]; then 
	turborama-utils turborama_backup restore no > /turborama/logs/last-restore.log 2>&1
fi

# Clean cache garbage when boot up.
rm -rf /storage/.cache/cores/* &

# handle SSH
DEFE=$(get_turborama_setting turborama_ssh.enabled)

case "${DEFE}" in
"0")
	systemctl stop sshd
	rm /storage/.cache/services/sshd.conf
	;;
*)
	mkdir -p /storage/.cache/services/
	touch /storage/.cache/services/sshd.conf
	systemctl start sshd
	;;
esac

# Checks and sets the resolution for starting ES.
check_res.sh

# Show splash creen 
show_splash.sh intro

# run custom_start before FE scripts
/storage/.config/custom_start.sh before &

# Just make sure all the subshells are finished before starting front-end
wait

# Start Scanning for Bluetooth Controllers
BTENABLED=$(get_turborama_setting turborama_bluetooth.enabled)
BTSCANTIME=$(get_turborama_setting turborama_bluetooth.scantime)
if [[ "${BTENABLED}" != "1" ]]; then
systemctl stop bluetooth
rm /storage/.cache/services/bluez.conf & 
else
systemctl restart bluetooth
turborama-bluetooth ${BTSCANTIME} &
fi

# Auto shutdown will persist between reboots as long as turborama_auto_shutdown_timeout is > 0
ASHD=$(get_turborama_setting turborama_auto_shutdown_persistent)

if [ "${ASHD}" != "1" ]; then 
	set_turborama_setting turborama_auto_shutdown_timeout 0
	set_turborama_setting turborama_auto_shutdown_persistent 0 # Paranoia 
fi
killall turborama_asd > /dev/null 2>&1 # Paranoia 
turborama_asd

# What to start at boot?
DEFE=$(get_turborama_setting turborama_boot)

case "${DEFE}" in
"Retroarch")
	rm -rf /var/lock/start.retro
	touch /var/lock/start.retro
	systemctl --no-block start retroarch
	;;
*)
	rm /var/lock/start.games
	touch /var/lock/start.games
    # emustation.service is ordered after this oneshot; waiting here deadlocks boot.
    systemctl --no-block start emustation
	;;
esac

# run custom_start ending scripts
/storage/.config/custom_start.sh after
