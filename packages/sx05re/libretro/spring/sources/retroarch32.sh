#!/usr/bin/env bash

export LD_LIBRARY_PATH="/turborama/lib32:$LD_LIBRARY_PATH"
exec /usr/bin/retroarch32 "$@"
