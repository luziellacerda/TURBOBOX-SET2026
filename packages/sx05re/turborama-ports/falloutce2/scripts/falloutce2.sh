
if ! test -f /storage/roms/ports/falloutce2/fallout2.cfg; then
  cp /usr/config/turborama/configs/falloutce2/fallout2.cfg /storage/roms/ports/falloutce2/
fi

fallout2-ce > /turborama/logs/turborama.log 2>&1
