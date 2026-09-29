#!/bin/bash

# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2019-present Shanti Gilbert (https://github.com/shantigilbert)

. /etc/profile
BIN="351Files"

init_port ${BIN} "default"

gptokeyb -c "/turborama/configs/gptokeyb/${BIN}.gptk" &

clear >/dev/console
turborama_console disable

if [ "${TURBORAMA_DEVICE}" == "OdroidGoAdvance" ] || [ "${TURBORAMA_DEVICE}" == "GameForce" ]; then
    
    clear >/dev/console
    
    case "$(oga_ver)" in
    "OGA"*)
        ${BIN} 480 320 14 24 24
    ;;
    "OGS")
        ${BIN} 854 480 14 24 24
    ;;
    "GF")
        ${BIN} 640 480 14 24 24
    ;;
        esac
else
    ${BIN}
fi

end_port
