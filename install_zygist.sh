#!/bin/bash

VERSION=v25.2
rand=$(cat /dev/urandom | tr -dc A-Za-z0-9|head -c 4)
rand1=$(cat /dev/urandom | tr -dc A-Za-z0-9|head -c 12)
rand2=$(cat /dev/urandom | tr -dc A-Za-z0-9|head -c 12)
rand3=$(cat /dev/urandom | tr -dc A-Za-z0-9|head -c 12)
rand4=$(cat /dev/urandom | tr -dc A-Za-z0-9|head -c 12)

CLEAN=1
REVERT=1
#refs:
#https://github.com/casualsnek/waydroid_script/issues/12
#https://github.com/LSPosed/MagiskOnWSA/blob/main/.github/workflows/magisk.yml#L162

############################################

waydroid session stop
sudo systemctl stop waydroid-container.service

IMG=$(cat /var/lib/waydroid/waydroid.cfg | grep images_path | cut -d' ' -f 3)/system.img
IMG_VENDOR=$(cat /var/lib/waydroid/waydroid.cfg | grep images_path | cut -d' ' -f 3)/vendor.img
MOUNT_DIR=/tmp/waydroid_system

while [ "$(mount | grep waydroid | cut -d" " -f3)" != "" ];do
for i in $(mount | grep waydroid | cut -d" " -f3);do sudo umount $i;done
echo retrying
sleep 1
done

####test
#sudo rm -rf /var/lib/waydroid/data/adb/magisk
#sudo rm /var/lib/waydroid/data/adb/magisk.db
#





##############INSTALL#******************



if test -f "Magisk-$VERSION.apk" ; then
    echo "Downloaded files founded"
else
    echo "Downloading Magisk $VERSION"
    wget https://github.com/topjohnwu/Magisk/releases/download/$VERSION/Magisk-$VERSION.apk
fi







cp Magisk-$VERSION.apk Magisk-$VERSION.apk.zip

sudo rm -rf magisk 2>/dev/null
mkdir magisk

sudo rm -rf /tmp/magisk_tmp 2>/dev/null
echo Unziping Magisk
unzip -q  Magisk-$VERSION.apk.zip -d /tmp/magisk_tmp 

###############RESIZE#######################



#SIZE=$(echo $(du -h -d0 /tmp/magisk_tmp | cut -d'M' -f1 )M)

#sudo qemu-img resize $IMG +$SIZE
#sudo e2fsck -f $IMG
#sudo resize2fs $IMG

#SIZE=$(echo $(du -h -d0 Magisk-$VERSION.apk.zip | cut -d'M' -f1 )M)
#For now fixed, until i check this
SIZE=30M
sudo qemu-img resize $IMG +$SIZE
sudo e2fsck -f $IMG
sudo resize2fs $IMG


##############################******************


mkdir $MOUNT_DIR 2>/dev/null 
sudo mount $IMG $MOUNT_DIR
#mkdir /tmp/waydroid_vendor/




sudo mount -o bind ~/.local/share/waydroid/data /var/lib/waydroid/data


cp /tmp/magisk_tmp/assets/boot_patch.sh magisk/boot_patch.sh
cp /tmp/magisk_tmp/lib/x86_64/libbusybox.so magisk/busybox
cp -r /tmp/magisk_tmp/assets/chromeos magisk/
cp /tmp/magisk_tmp/lib/x86/libmagisk32.so magisk/magisk32 
cp /tmp/magisk_tmp/lib/x86_64/libmagisk64.so magisk/magisk64
cp /tmp/magisk_tmp/lib/x86_64/libmagiskboot.so magisk/magiskboot
cp /tmp/magisk_tmp/lib/x86_64/libmagiskinit.so magisk/magiskinit
cp /tmp/magisk_tmp/lib/x86_64/libmagiskpolicy.so magisk/magiskpolicy
cp /tmp/magisk_tmp/assets/util_functions.sh magisk/util_functions.sh
cp -r /tmp/magisk_tmp/assets/chromeos magisk/
cp /tmp/magisk_tmp/assets/util_functions.sh magisk/util_functions.sh


rm -rf magiskxz
mkdir magiskxz
cp /tmp/magisk_tmp/lib/x86_64/libmagisk64.so magiskxz/magisk64
cp /tmp/magisk_tmp/lib/x86/libmagisk32.so magiskxz/magisk32 
xz magiskxz/magisk32 
xz magiskxz/magisk64 

#sudo mkdir /var/lib/waydroid/data/adb/module
sudo mkdir $MOUNT_DIR/system/sbin 2>/dev/null 
sudo chcon --reference $MOUNT_DIR/system/init.environ.rc $MOUNT_DIR/system/sbin
sudo chown root:root $MOUNT_DIR/system/sbin
sudo chmod 0700 $MOUNT_DIR/system/sbin
#######################sudo cp magisk/* $MOUNT_DIR/sbin/






############DEGUB ONLY
#sudo rm -rf /var/lib/waydroid/data/adb/magisk
#sudo rm /var/lib/waydroid/data/adb/magisk.db
#################


############# Minimal to Magisk
sudo cp magiskxz/* $MOUNT_DIR/sbin/
################

############INIT
if [ $REVERT == 0 ];then
#sudo cp /var/lib/waydroid/data/adb/magisk/magiskinit $MOUNT_DIR/system/bin/init
#sudo ln -s /init $MOUNT_DIR/system/bin/init
sudo rm $MOUNT_DIR/init
sudo cp /var/lib/waydroid/data/adb/magisk/magiskinit $MOUNT_DIR/init
sudo chmod 777 $MOUNT_DIR/init
sudo chmod -R 777 $MOUNT_DIR/sbin/
fi
if [ $REVERT == 1 ];then
sudo rm $MOUNT_DIR/init
sudo ln -s /system/bin/init $MOUNT_DIR/init
fi
###########

sudo mkdir -p /var/lib/waydroid/data/adb/magisk
sudo chmod -R 700 /var/lib/waydroid/data/adb
sudo cp -r magisk/* /var/lib/waydroid/data/adb/magisk/
sudo find /var/lib/waydroid/data/adb/magisk -type f -exec chmod 0755 {} \;
sudo cp Magisk-$VERSION.apk.zip /var/lib/waydroid/data/adb/magisk/magisk.apk



sudo find $MOUNT_DIR/system/sbin -type f -exec chmod 0755 {} \;
sudo find $MOUNT_DIR/system/sbin -type f -exec chown root:root {} \;
sudo find $MOUNT_DIR/system/sbin -type f -exec chcon --reference $MOUNT_DIR/system/product {} \;
#chmod +x ./magiskpolicy
#echo '/dev/$rand(/.*)?    u:object_r:magisk_file:s0' | sudo tee -a $MOUNT_DIR/system/vendor/etc/selinux/vendor_file_contexts
#echo '/data/adb/magisk(/.*)?   u:object_r:magisk_file:s0' | sudo tee -a $MOUNT_DIR/system/vendor/etc/selinux/vendor_file_contexts
#sudo ./magiskpolicy --load $MOUNT_DIR/system/vendor/etc/selinux/precompiled_sepolicy --save $MOUNT_DIR/system/vendor/etc/selinux/precompiled_sepolicy --magisk "allow * magisk_file lnk_file *"

#sudo tee -a $MOUNT_DIR/system/etc/init/hw/init.rc <<EOF
#A10?




sudo umount $IMG_VENDOR 2>/dev/null
sudo umount $IMG_VENDOR 2>/dev/null
sudo umount $IMG_VENDOR 2>/dev/null

while [ "$(mount | grep waydroid | cut -d" " -f3)" != "" ];do
for i in $(mount | grep waydroid | cut -d" " -f3);do sudo umount $i;done
echo retrying
sleep 1
done

####
#CLEANING UP
if [ $CLEAN == 1 ];then
sudo rm -rf magisk
sudo rm -rf $MOUNT_DIR
sudo rm -rf magiskxz
sudo rm -rf /tmp/magisk_tmp/
rm Magisk-$VERSION.apk.zip
fi

###########
#Dont know why, but it was needed one time
sudo /usr/lib/waydroid/data/scripts/waydroid-net.sh  stop
#
sudo systemctl stop waydroid-container.service
sudo systemctl start waydroid-container.service
