#!/bin/bash

#refs:
#https://github.com/casualsnek/waydroid_script/issues/12
#https://github.com/LSPosed/MagiskOnWSA/blob/main/.github/workflows/magisk.yml#L162

############################################

waydroid session stop
sudo systemctl stop waydroid-container.service

IMG=$(cat /var/lib/waydroid/waydroid.cfg | grep images_path | cut -d' ' -f 3)/system.img
IMG_VENDOR=$(cat /var/lib/waydroid/waydroid.cfg | grep images_path | cut -d' ' -f 3)/vendor.img
MOUNT_DIR=/tmp/waydroid_system

sudo umount $IMG
sudo umount $IMG_VENDOR


###############RESIZE#######################
#SIZE=$(echo $(du -h -d0 XXXXXXXXXXX | cut -d'M' -f1)M) 

#sudo qemu-img resize $IMG +$SIZE
#sudo e2fsck -f $IMG
#sudo resize2fs $IMG


##############################******************

mkdir $MOUNT_DIR
sudo mount $IMG $MOUNT_DIR
#mkdir /tmp/waydroid_vendor/
sudo mv $MOUNT_DIR/system/vendor $MOUNT_DIR/system/vendor.bkp
sudo mkdir $MOUNT_DIR/system/vendor
sudo mount $IMG_VENDOR $MOUNT_DIR/system/vendor




##############INSTALL#******************


#!/bin/bash

IMG=$(cat /var/lib/waydroid/waydroid.cfg | grep images_path | cut -d' ' -f 3)/system.img
IMG_VENDOR=$(cat /var/lib/waydroid/waydroid.cfg | grep images_path | cut -d' ' -f 3)/vendor.img
MOUNT_DIR=/tmp/waydroid_system

wget https://github.com/topjohnwu/Magisk/releases/download/v24.1/Magisk-v24.1.apk
mv Magisk-v24.1.apk magisk.zip

sudo rm -rf magisk
mkdir magisk

sudo rm -rf /tmp/magisk_tmp
unzip magisk -d /tmp/magisk_tmp

sudo umount /var/lib/waydroid/data
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

sudo mkdir $MOUNT_DIR/system/sbin
sudo chcon --reference $MOUNT_DIR/system/init.environ.rc $MOUNT_DIR/system/sbin
sudo chown root:root $MOUNT_DIR/system/sbin
sudo chmod 0700 $MOUNT_DIR/system/sbin
sudo cp magisk/* $MOUNT_DIR/system/sbin/
sudo mkdir -p ~/.local/share/waydroid/data/adb/magisk
sudo chmod -R 700 ~/.local/share/waydroid/data/adb
sudo cp magisk/* ~/.local/share/waydroid/data/adb/magisk/
sudo find ~/.local/share/waydroid/data/adb/magisk -type f -exec chmod 0755 {} \;
sudo cp magisk.zip ~/.local/share/waydroid/data/adb/magisk/magisk.apk
sudo tee -a $MOUNT_DIR/system/sbin/loadpolicy.sh <<EOF
#!/system/bin/sh
restorecon -R /data/adb/magisk
for module in \$(ls /data/adb/modules); do
    if ! [ -f "/data/adb/modules/\$module/disable" ] && [ -f "/data/adb/modules/\$module/sepolicy.rule" ]; then
        /sbin/magiskpolicy --live --apply "/data/adb/modules/\$module/sepolicy.rule"
    fi
done
EOF

sudo find $MOUNT_DIR/system/sbin -type f -exec chmod 0755 {} \;
sudo find $MOUNT_DIR/system/sbin -type f -exec chown root:root {} \;
sudo find $MOUNT_DIR/system/sbin -type f -exec chcon --reference $MOUNT_DIR/system/product {} \;
chmod +x ./magiskpolicy
echo '/dev/waydroid-magisk(/.*)?    u:object_r:magisk_file:s0' | sudo tee -a $MOUNT_DIR/system/vendor/etc/selinux/vendor_file_contexts
echo '/data/adb/magisk(/.*)?   u:object_r:magisk_file:s0' | sudo tee -a $MOUNT_DIR/system/vendor/etc/selinux/vendor_file_contexts
sudo ./magiskpolicy --load $MOUNT_DIR/system/vendor/etc/selinux/precompiled_sepolicy --save $MOUNT_DIR/system/vendor/etc/selinux/precompiled_sepolicy --magisk "allow * magisk_file lnk_file *"
sudo tee -a $MOUNT_DIR/system/etc/init/hw/init.rc <<EOF
on post-fs-data
    start logd
    start adbd
    mkdir /dev/waydroid-magisk
    mount tmpfs tmpfs /dev/waydroid-magisk mode=0755
    copy /data/adb/magisk/magisk64 /dev/waydroid-magisk/magisk64
    chmod 0755 /dev/waydroid-magisk/magisk64
    symlink ./magisk64 /dev/waydroid-magisk/magisk
    symlink ./magisk64 /dev/waydroid-magisk/su
    symlink ./magisk64 /dev/waydroid-magisk/resetprop
    copy /sbin/magisk32 /dev/waydroid-magisk/magisk32
    chmod 0755 /dev/waydroid-magisk/magisk32
    copy /data/adb/magisk/magiskinit /dev/waydroid-magisk/magiskinit
    chmod 0755 /dev/waydroid-magisk/magiskinit
    symlink ./magiskinit /dev/waydroid-magisk/magiskpolicy
    mkdir /dev/waydroid-magisk/.magisk 700
    mkdir /dev/waydroid-magisk/.magisk/mirror 700
    mkdir /dev/waydroid-magisk/.magisk/block 700
    mount none /data /dev/waydroid-magisk/.magisk/mirror/data bind rec
    rm /dev/.magisk_unblock
    start IhhslLhHYfse
    start FAhW7H9G5sf
    wait /dev/.magisk_unblock 40
    rm /dev/.magisk_unblock
service IhhslLhHYfse /system/bin/sh /sbin/loadpolicy.sh
    user root
    seclabel u:r:magisk:s0
    oneshot
service FAhW7H9G5sf /dev/waydroid-magisk/magisk --post-fs-data
    user root
    seclabel u:r:magisk:s0
    oneshot
service HLiFsR1HtIXVN6 /dev/waydroid-magisk/magisk --service
    class late_start
    user root
    seclabel u:r:magisk:s0
    oneshot
on property:sys.boot_completed=1
    start YqCTLTppv3ML
service YqCTLTppv3ML /dev/waydroid-magisk/magisk --boot-complete
    user root
    seclabel u:r:magisk:s0
    oneshot
EOF


##############################******************
sudo umount $IMG_VENDOR
sudo rm -rf $MOUNT_DIR/system/vendor
sudo mv $MOUNT_DIR/system/vendor.bkp $MOUNT_DIR/system/vendor
sudo umount /var/lib/waydroid/data
sudo umount $MOUNT_DIR

sudo systemctl start waydroid-container.service