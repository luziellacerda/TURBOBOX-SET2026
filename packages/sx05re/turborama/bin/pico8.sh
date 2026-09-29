#!/bin/bash

# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2020-present Shanti Gilbert (https://github.com/shantigilbert)

. /etc/profile

# If there is a new version copy the files
if [[ -e "/storage/roms/bios/pico-8" ]]; then
    mkdir -p /turborama/bin/pico-8
    cp -rf /storage/roms/bios/pico-8/* /turborama/bin/pico-8
    rm -rf /storage/roms/bios/pico-8
    chmod +x /turborama/bin/pico-8/pico8_dyn
    touch /storage/roms/pico-8/splore.p8
    
fi 

if [ ! -L "/storage/.config/turborama/configs/pico-8/bbs/carts" ]; then
    mkdir -p /storage/.config/turborama/configs/pico-8/bbs/
    ln -sf /storage/roms/pico-8 /storage/.config/turborama/configs/pico-8/bbs/carts
fi

if [[ "${TURBORAMA_DEVICE}" == "Amlogic-old" ]]; then
set_audio alsa
mv /storage/.config/asound.conf /storage/.config/asound.conf2
fi

mkdir -p /turborama/configs/pico-8

if [[ ! -L "/turborama/configs/pico-8/sdl_controllers.txt" ]]; then
    rm /turborama/configs/pico-8/sdl_controllers.txt
    ln -sf /storage/.config/SDL-GameControllerDB/gamecontrollerdb.txt /turborama/configs/pico-8/sdl_controllers.txt
fi

#LD_LIBRARY_PATH="/turborama/lib32:${LD_LIBRARY_PATH}"

CART="${1}"

if [[ "${CART}" == *"/splore"* ]]; then
    /turborama/bin/pico-8/pico8_dyn -splore -home /turborama/configs/pico-8 -root_path /storage/roms/pico-8 -joystick 0
else
    /turborama/bin/pico-8/pico8_dyn -run "${CART}" -home /turborama/configs/pico-8 -root_path /storage/roms/pico-8 -joystick 0
fi

if [[ "${TURBORAMA_DEVICE}" == "Amlogic-old" ]]; then
set_audio default
mv /storage/.config/asound.conf2 /storage/.config/asound.conf
fi

