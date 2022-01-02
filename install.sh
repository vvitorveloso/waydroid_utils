#!/bin/bash

sudo systemctl stop waydroid-container.service
sudo umount /var/lib/waydroid/images/system.img
sudo umount /var/lib/waydroid/images/vendor.img


A11_URL="https://sourceforge.net/projects/blissos-dev/files/waydroid/lineage/lineage-18.1/Lineage-OS-18.1-waydroid_x86_64-202111291420-foss-sd-hd-ex_ax86-vaapi_gles-aep.zip/download"

wget $A11_URL -O waydroid_lineage_18.zip


sudo rm -rf waydroid_lineage_18

unzip -d waydroid_lineage_18 ./waydroid_lineage_18.zip




sudo cp anbox.conf  /etc/gbinder.d/anbox.conf 
sudo cp gbinder.conf  /etc/gbinder.conf

sudo cp waydroid_lineage_18/vendor.img /var/lib/waydroid/images/vendor.img
sudo cp waydroid_lineage_18/system.img /var/lib/waydroid/images/system.img


sudo bash ./PlayStore_Waydroid_11.sh

sudo umount /var/lib/waydroid/images/system.img
sudo umount /var/lib/waydroid/images/vendor.img

git clone https://github.com/casualsnek/waydroid_script
cd waydroid_script
sudo python3 -m pip install -r requirements.txt
#sudo python3 waydroid_extras.py [-i/-g/-n/-h]

sudo systemctl start waydroid-container.service

sudo python3 waydroid_extras.py -h

sudo python3 waydroid_extras.py -i
