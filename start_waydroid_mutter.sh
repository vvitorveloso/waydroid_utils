#!/bin/bash
sudo systemctl stop waydroid-container.service

sudo systemctl start waydroid-container.service
sleep 3
MUTTER_DEBUG_DUMMY_MODE_SPECS=1356x707 mutter --wayland --nested &
XDG_SESSION_TYPE=wayland waydroid show-full-ui
killall mutter

sudo systemctl stop waydroid-container.service

