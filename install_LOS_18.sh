#!/bin/bash

sudo systemctl stop waydroid-container.service
IMG=$(cat /var/lib/waydroid/waydroid.cfg | grep images_path | cut -d' ' -f 3)/system.img
IMG_VENDOR=$(cat /var/lib/waydroid/waydroid.cfg | grep images_path | cut -d' ' -f 3)/vendor.img
MOUNT_DIR=/tmp/waydroid_system
sudo umount $IMG
sudo umount $IMG_VENDOR

A11_URL="https://sourceforge.net/projects/blissos-dev/files/waydroid/lineage/lineage-18.1/Lineage-OS-18.1-waydroid_x86_64-202111291420-foss-sd-hd-ex_ax86-vaapi_gles-aep.zip/download"

if [ ! -f waydroid_lineage_18.zip ]; then
wget $A11_URL -O waydroid_lineage_18.zip
fi

sudo rm -rf waydroid_lineage_18

unzip -d waydroid_lineage_18 ./waydroid_lineage_18.zip




sudo cp anbox.conf  /etc/gbinder.d/anbox.conf 
sudo cp gbinder.conf  /etc/gbinder.conf

sudo cp waydroid_lineage_18/vendor.img $IMG_VENDOR
sudo cp waydroid_lineage_18/system.img $IMG


git clone https://github.com/casualsnek/waydroid_script
cd waydroid_script
#sudo python3 -m pip install -r requirements.txt
#sudo python3 waydroid_extras.py [-i/-g/-n/-h]

sudo systemctl start waydroid-container.service

sudo python3 waydroid_extras.py -h

sudo python3 waydroid_extras.py -i
