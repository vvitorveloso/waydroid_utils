#!/bin/bash

VERSION=v25.1
rand=$(cat /dev/urandom | tr -dc A-Za-z0-9|head -c 4)
rand1=$(cat /dev/urandom | tr -dc A-Za-z0-9|head -c 12)
rand2=$(cat /dev/urandom | tr -dc A-Za-z0-9|head -c 12)
rand3=$(cat /dev/urandom | tr -dc A-Za-z0-9|head -c 12)
rand4=$(cat /dev/urandom | tr -dc A-Za-z0-9|head -c 12)

CLEAN=1
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

#SIZE=$(echo $(du -h -d0 Magisk-$VERSION.apk.zip | cut -d'M' -f1 )M)
#For now fixed, until i check this
SIZE=10M
sudo qemu-img resize IMG_VENDOR +$SIZE
sudo e2fsck -f IMG_VENDOR
sudo resize2fs IMG_VENDOR

##############################******************


mkdir $MOUNT_DIR 2>/dev/null 
sudo mount $IMG $MOUNT_DIR
#mkdir /tmp/waydroid_vendor/
sudo rm -rf $MOUNT_DIR/system/vendor 
sudo mkdir $MOUNT_DIR/system/vendor 
sudo mount $IMG_VENDOR $MOUNT_DIR/system/vendor



sudo mount -o bind ~/.local/share/waydroid/data /var/lib/waydroid/data

cp /tmp/magisk_tmp/lib/x86_64/libmagisk64.so magisk/magisk64
cp /tmp/magisk_tmp/lib/x86/libmagisk32.so magisk/magisk32 
cp /tmp/magisk_tmp/lib/x86_64/libmagiskinit.so magisk/magiskinit
cp /tmp/magisk_tmp/lib/x86_64/libmagiskinit.so magisk/magiskpolicy
cp /tmp/magisk_tmp/lib/x86_64/libmagiskboot.so magisk/magiskboot
cp /tmp/magisk_tmp/lib/x86_64/libbusybox.so magisk/busybox
cp /tmp/magisk_tmp/lib/x86_64/libmagiskinit.so magiskpolicy
cp /tmp/magisk_tmp/assets/boot_patch.sh magisk/boot_patch.sh
cp /tmp/magisk_tmp/assets/util_functions.sh magisk/util_functions.sh
cp -r /tmp/magisk_tmp/assets/chromeos magisk/


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
#sudo cp /var/lib/waydroid/data/adb/magisk/magiskinit $MOUNT_DIR/system/bin/init
#sudo ln -s /init $MOUNT_DIR/system/bin/init
#sudo cp /var/lib/waydroid/data/adb/magisk/magiskinit $MOUNT_DIR/init
#sudo rm $MOUNT_DIR/init
sudo cp magiskxz/* $MOUNT_DIR/sbin/
###########

sudo mkdir -p /var/lib/waydroid/data/adb/magisk
sudo chmod -R 700 /var/lib/waydroid/data/adb
sudo cp -r magisk/* /var/lib/waydroid/data/adb/magisk/
sudo find /var/lib/waydroid/data/adb/magisk -type f -exec chmod 0755 {} \;
sudo cp Magisk-$VERSION.apk.zip /var/lib/waydroid/data/adb/magisk/magisk.apk
#####################
########
###
## MUST MAKE BACKUP
##################
VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV
sudo rm $MOUNT_DIR/system/sbin/loadpolicy.sh
sudo tee -a $MOUNT_DIR/system/sbin/loadpolicy.sh <<EOF
#!/system/bin/sh
restorecon -R /data/adb/magisk
for module in \$(ls /data/adb/modules); do
    if ! [ -f "/data/adb/modules/\$module/disable" ] && [ -f "/data/adb/modules/\$module/sepolicy.rule" ]; then
        /sbin/magiskpolicy --live --apply "/data/adb/modules/\$module/sepolicy.rule"
    fi
done
EOF





    #mount none /data /dev/$rand/.magisk/block/data bind rec
    #mount none /data /dev/$rand/.magisk/mirror/data  bind rec

sudo find $MOUNT_DIR/system/sbin -type f -exec chmod 0755 {} \;
sudo find $MOUNT_DIR/system/sbin -type f -exec chown root:root {} \;
sudo find $MOUNT_DIR/system/sbin -type f -exec chcon --reference $MOUNT_DIR/system/product {} \;
chmod +x ./magiskpolicy
echo '/dev/$rand(/.*)?    u:object_r:magisk_file:s0' | sudo tee -a $MOUNT_DIR/system/vendor/etc/selinux/vendor_file_contexts
echo '/data/adb/magisk(/.*)?   u:object_r:magisk_file:s0' | sudo tee -a $MOUNT_DIR/system/vendor/etc/selinux/vendor_file_contexts
#sudo ./magiskpolicy --load $MOUNT_DIR/system/vendor/etc/selinux/precompiled_sepolicy --save $MOUNT_DIR/system/vendor/etc/selinux/precompiled_sepolicy --magisk "allow * magisk_file lnk_file *"

#sudo tee -a $MOUNT_DIR/system/etc/init/hw/init.rc <<EOF
#A10?



#sudo cp /var/lib/waydroid/data/adb/init.rc /tmp/init.rc


if sudo test -f "$MOUNT_DIR/system/etc/init/hw/init.rc" ; then
    echo "A11"
    INITX="$MOUNT_DIR/system/etc/init/hw/init.rc"
else
    echo "A10"
    INITX="$MOUNT_DIR/init.rc"
fi


BKPINIT=/var/lib/waydroid/data/adb/init.rc


if sudo test -f "$BKPINIT" ; then
    echo "Backup found from $INITX"
else
   echo "making backup from $INITX"
   sudo cp $INITX $BKPINIT
fi

echo sudo cp $BKPINIT $INITX
sudo cp $BKPINIT $INITX

sudo tee -a $INITX <<EOF
on post-fs-data
    start logd
    start adbd
    mkdir /dev/$rand
    mount tmpfs tmpfs /dev/$rand mode=0755
    copy /data/adb/magisk/magisk64 /dev/$rand/magisk64
    copy /data/adb/magisk/magisk32 /dev/$rand/magisk32
    copy /data/adb/magisk/magiskinit /dev/$rand/magiskinit
    chmod 0755 /dev/$rand/magisk64
    symlink ./magisk64 /dev/$rand/magisk
    symlink ./magisk64 /dev/$rand/su
    symlink ./magisk64 /dev/$rand/resetprop
    symlink ./magisk64 /dev/$rand/supolicy
    chmod 0755 /dev/$rand/magisk32
    chmod 0755 /dev/$rand/magiskinit
    symlink ./magiskinit /dev/$rand/magiskpolicy
    mkdir /dev/$rand/.magisk 700
    mkdir /dev/$rand/.magisk/mirror 700
    mkdir /dev/$rand/.magisk/mirror/data 700
    mkdir /dev/$rand/.magisk/block 700
    mkdir /dev/$rand/.magisk/zygisk
    mount none /data /dev/$rand/.magisk/mirror/data bind rec  
    rm /dev/.magisk_unblock
    start $rand1
    start $rand2
    wait /dev/.magisk_unblock 40
    rm /dev/.magisk_unblock

service $rand1 /system/bin/sh /sbin/loadpolicy.sh
    user root
    seclabel u:r:magisk:s0
    oneshot

service $rand2 /dev/$rand/magisk --post-fs-data
    user root
    seclabel u:r:magisk:s0
    oneshot


service $rand3 /dev/$rand/magisk --service
    class late_start
    user root
    seclabel u:r:magisk:s0
    oneshot

on property:sys.boot_completed=1
    start $rand4

service $rand4 /dev/$rand/magisk --boot-complete
    user root
    seclabel u:r:magisk:s0
    oneshot

EOF

#################
#echo checking
#echo $INITX
#sudo cat $INITX
#################

sudo umount $IMG_VENDOR 2>/dev/null
sudo umount $IMG_VENDOR 2>/dev/null
sudo umount $IMG_VENDOR 2>/dev/null
sudo rm -rf $MOUNT_DIR/system/vendor 
sudo ln -s /vendor $MOUNT_DIR/system/vendor

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
