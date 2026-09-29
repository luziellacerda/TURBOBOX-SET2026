#!/bin/bash

# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2020-present Shanti Gilbert (https://github.com/shantigilbert)

valid_version() {
  [[ "$1" =~ ^[0-9]+(\.[0-9]+)*(-[A-Za-z0-9._-]+)?$ ]]
}

newer_version() {
  valid_version "$1" && valid_version "$2" || return 1
  [[ "$1" != "$2" && "$(printf '%s\n%s\n' "$1" "$2" | sort -V | head -n 1)" == "$2" ]]
}

update_filename() {
  local device="$1" version="$2" suffix=""
  valid_version "$version" || return 1
  case "$device" in
    Amlogic-ng|Amlogic-no|Amlogic-old) ;;
    OdroidGoAdvance) suffix="-odroidgo2" ;;
    GameForce) suffix="-chi" ;;
    RK356x) suffix="-rk356x" ;;
    *) return 1 ;;
  esac
  printf 'Turborama-%s.aarch64-%s%s.tar\n' "$device" "$version" "$suffix"
}

verify_update() {
  local archive="$1" checksum="$2" image_name="$3" expected actual entries
  read -r expected _ < "$checksum" || return 1
  [[ "$expected" =~ ^[[:xdigit:]]{64}$ ]] || return 1
  actual=$(sha256sum "$archive") || return 1
  [[ "${actual%% *}" == "${expected,,}" ]] || return 1
  entries=$(tar -tf "$archive") || return 1
  grep -Fxq "$image_name/target/SYSTEM" <<< "$entries" &&
    grep -Fxq "$image_name/target/KERNEL" <<< "$entries"
}

publish_update() {
  local archive="$1" checksum="$2" image_name="$3" destination="$4"
  [[ "$image_name" == Turborama-* && "$image_name" != */* ]] || return 1
  verify_update "$archive" "$checksum" "$image_name" || return 1
  # Never expose an unverified archive or replace a previously staged update.
  if compgen -G "$destination/*.tar" >/dev/null ||
     compgen -G "$destination/*.img.gz" >/dev/null ||
     compgen -G "$destination/*.img" >/dev/null; then
    echo "An update is already staged; it has been preserved." >&2
    return 1
  fi
  mv -- "$archive" "$destination/$image_name.tar"
}

update_cleanup() {
  if [[ -n "${UPDATE_WORK:-}" && -d "$UPDATE_WORK" ]]; then
    rm -rf -- "$UPDATE_WORK"
  fi
  if [[ "${UPDATE_CONSOLE:-0}" == 1 ]]; then
    turborama_console disable
    systemctl start emustation.service
  fi
}

update_main() {
  . /etc/profile
  local mode="${1:-canupdate}" channel current version device file url catalog
  local info_url="https://raw.githubusercontent.com/luziellacerda/TURBOBOX-SET2026/main/settings/TURBORAMA_update"
  local release_url="https://github.com/luziellacerda/TURBOBOX-SET2026/releases/download"
  local -a curl_opts=(-fLsS --connect-timeout 10 --max-time 30 --retry 1)

  case "$mode" in canupdate|geturl|getsize|stageupdate|forceupdate) ;; *) return 1 ;; esac
  channel=$(get_turborama_setting updates.type)
  [[ -n "$channel" ]] || channel="stable"
  catalog=$(curl "${curl_opts[@]}" "$info_url") || { echo no; return 1; }
  version=$(awk -F';' -v channel="$channel" '$0 !~ /^#/ && $2 == channel {print $1; exit}' <<< "${catalog//$'\r'/}")
  valid_version "$version" || { echo no; return 1; }
  current=$(cat /usr/config/TURBORAMA_VERSION) || return 1
  # Use the compiled device identity: SoC detection can return a different family.
  device=$(cat /turborama_arch) || return 1
  file=$(update_filename "$device" "$version") || { echo no; return 1; }
  url="$release_url/v$version/$file"
  if [[ "$mode" != forceupdate ]] && ! newer_version "$version" "$current"; then
    echo no
    return 1
  fi
  curl "${curl_opts[@]}" --head "$url" >/dev/null || { echo no; return 1; }
  case "$mode" in
    canupdate) echo "$version"; return ;;
    geturl) echo "$url"; return ;;
    getsize)
      curl "${curl_opts[@]}" --head "$url" | awk 'tolower($1) == "content-length:" {gsub(/\r/, "", $2); size=$2} END {print size}'
      return ;;
  esac

  mkdir -p /storage/.update || return 1
  exec 9>/storage/.update/.turborama-update.lock
  flock -n 9 || return 1
  UPDATE_WORK=$(mktemp -d /storage/.update/.turborama-update.XXXXXX) || return 1
  UPDATE_CONSOLE=0
  trap update_cleanup EXIT
  trap 'exit 1' INT TERM
  if [[ "$mode" == forceupdate ]]; then
    systemctl stop emustation.service
    turborama_console enable
    UPDATE_CONSOLE=1
    text_viewer -y -w -t "Turborama update" -f 24 -m "Install Turborama ${version}? The system will restart after the download is verified."
    [[ $? == 21 ]] || return 1
    echo "Downloading Turborama ${version}..." > /dev/tty0
  else
    echo "Downloading Turborama ${version}..."
  fi
  if ! curl -fL --connect-timeout 15 --retry 2 "$url" -o "$UPDATE_WORK/payload" ||
     ! curl "${curl_opts[@]}" "$url.sha256" -o "$UPDATE_WORK/checksum" ||
     ! publish_update "$UPDATE_WORK/payload" "$UPDATE_WORK/checksum" "${file%.tar}" /storage/.update; then
    if [[ "$mode" == forceupdate ]]; then
      text_viewer -e -w -t "Update aborted" -f 24 -m "Download or verification failed, or an update is already staged. Existing updates have been preserved."
    else
      echo "Update aborted. Download or verification failed, or an update is already staged." >&2
    fi
    return 1
  fi
  sync
  if [[ "$mode" == stageupdate ]]; then
    echo "Update verified. Reboot Turborama to apply it."
    return 0
  fi
  systemctl reboot || return 1
  UPDATE_CONSOLE=0
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  update_main "$@"
fi
