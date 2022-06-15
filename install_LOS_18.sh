#!/bin/bash


sudo systemctl stop waydroid-container.service
IMG=$(cat /var/lib/waydroid/waydroid.cfg | grep images_path | cut -d' ' -f 3)/system.img
IMG_VENDOR=$(cat /var/lib/waydroid/waydroid.cfg | grep images_path | cut -d' ' -f 3)/vendor.img
MOUNT_DIR=/tmp/waydroid_system
MOUNT_VENDOR_DIR=/tmp/waydroid_vendor/
sudo umount $IMG
sudo umount $IMG_VENDOR
mkdir $MOUNT_DIR

#Uncoment if you want to remove all
#sudo rm -rf /var/lib/waydroid/ ~/.local/share/{waydroid,applications/waydroid}


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

echo "waydroid.active_apps=Waydroid" | sudo tee -a  /var/lib/waydroid/waydroid_base.prop
sudo sed -i 's/^waydroid.system_ota=.*/waydroid.system_ota=/' /var/lib/waydroid/waydroid_base.prop
sudo sed -i 's/^waydroid.vendor_ota=.*/waydroid.vendor_ota=/' /var/lib/waydroid/waydroid_base.prop

sudo mount $IMG $MOUNT_DIR



sudo sed -i '/setprop sys.use_memfd/s/false/true/' $MOUNT_DIR/system/etc/init/hw/init.rc


sudo umount $IMG
#sudo umount $IMG_VENDOR

sudo systemctl start waydroid-container.service

