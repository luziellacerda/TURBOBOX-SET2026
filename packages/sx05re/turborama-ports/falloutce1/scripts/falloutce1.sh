
if ! test -f /storage/roms/ports/falloutce1/fallout.cfg; then
  cp /usr/config/turborama/configs/falloutce1/fallout.cfg /storage/roms/ports/falloutce1/
fi

fallout-ce > /turborama/logs/turborama.log 2>&1
