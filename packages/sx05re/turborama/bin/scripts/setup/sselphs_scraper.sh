#!/bin/bash

# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2019-present Shanti Gilbert (https://github.com/shantigilbert)

# Source predefined functions and variables
. /etc/profile

turborama_console enable

function scrape_confirm() {
	text_viewer -y -w -t "Sselph's Scraper" -f 24 -m "This will Kill Emulationstation and will start Sselph's Scraper, do you want to continue?\n\nYou will need a keyboard to be able to use the scraping menu"
    [[ $? == 21 ]] && start_scraper || exit 0;
 }

function start_scraper() {
turborama_console enable
systemd-run bash /usr/bin/scripts/setup/scraper.start
systemctl stop emustation
}

turborama_console disable
scrape_confirm

