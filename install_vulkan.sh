#!/bin/bash

############################################
####VULKAN
waydroid session stop
sudo systemctl stop waydroid-container.service

IMG=$(cat /var/lib/waydroid/waydroid.cfg | grep images_path | cut -d' ' -f 3)/system.img
IMG_VENDOR=$(cat /var/lib/waydroid/waydroid.cfg | grep images_path | cut -d' ' -f 3)/vendor.img
MOUNT_DIR=/tmp/waydroid_system

mkdir $MOUNT_DIR
sudo mount $IMG $MOUNT_DIR
mkdir /tmp/waydroid_vendor/
sudo mount $IMG_VENDOR /tmp/waydroid_vendor/


for i in $(ls vulkan/vendor);do sudo cp -aR ./vulkan/vendor/$i /tmp/waydroid_vendor/;done

sudo cp -aR ./vulkan/etc $MOUNT_DIR/system/

### FOR TEST
#sudo cp -aR ./vulkan/lib64 $MOUNT_DIR/system/
#sudo cp -aR ./vulkan/lib $MOUNT_DIR/system/
##

sudo umount $MOUNT_DIR
sudo umount $IMG_VENDOR

echo ro.hardware.vulkan.level=1 | sudo tee -a /var/lib/waydroid/waydroid_base.prop
echo ro.hardware.vulkan.version=4194307 | sudo tee -a /var/lib/waydroid/waydroid_base.prop
#echo ro.hardware.vulkan=android-x86 | sudo tee -a /var/lib/waydroid/waydroid_base.prop
echo ro.hardware.vulkan=radv | sudo tee -a /var/lib/waydroid/waydroid_base.prop

############




sudo systemctl start waydroid-container.service