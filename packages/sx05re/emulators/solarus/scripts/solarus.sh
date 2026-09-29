#!/bin/bash

# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2021-present Shanti Gilbert (https://github.com/shantigilbert)

# Source predefined functions and variables
. /etc/profile

[[ ! -d "/turborama/configs/solarus/saves/" ]] && mkdir -p "/turborama/configs/solarus/saves/"

if [ "${TURBORAMA_DEVICE}" == "OdroidGoAdvance" ] || [ "${TURBORAMA_DEVICE}" == "Amlogic-ng" ] || [ "${TURBORAMA_DEVICE}" == "GameForce" ]; then
    gptokeyb -c /turborama/configs/gptokeyb/solarus-run.gptk &
    SDL_GAMECONTROLLERCONFIG_FILE="" solarus-run -fullscreen=yes ${1}
    killall gptokeyb
else
    solarus-run -fullscreen=yes ${1}
fi

exit 0
