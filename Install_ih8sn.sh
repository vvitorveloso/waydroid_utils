#sudo pacman -S qemu

#ZERO_BINS >>>> find /proc/sys/fs/binfmt_misc -type f -name 'arm*' -exec sudo sh -c 'echo -1 > {}' \;

waydroid session stop
sudo systemctl stop waydroid-container.service

IMG=$(cat /var/lib/waydroid/waydroid.cfg | grep images_path | cut -d' ' -f 3)/system.img
IMG_VENDOR=$(cat /var/lib/waydroid/waydroid.cfg | grep images_path | cut -d' ' -f 3)/vendor.img
MOUNT_DIR=/tmp/waydroid_system
TMP_DIR=/tmp/opengapps/system/

sudo umount $IMG
mkdir $MOUNT_DIR
sudo mount $IMG $MOUNT_DIR

rm -rf ih8sn-x86_64.zip 
wget https://github.com/luk1337/ih8sn/releases/download/latest/ih8sn-x86_64.zip

rm -rf ih8sn 
unzip -d ih8sn ih8sn-x86_64.zip 

sudo cp -a ./ih8sn/60-ih8sn.sh $MOUNT_DIR/system/addon.d/
sudo cp -a ./ih8sn/ih8sn $MOUNT_DIR/system/bin/
sudo cp -a ./ih8sn.conf  $MOUNT_DIR/system/etc/
sudo cp -a ./ih8sn/ih8sn.rc $MOUNT_DIR/system/etc/init/

echo ro.build.fingerprint="OnePlus/OnePlus7Pro_EEA/OnePlus7Pro:10/QKQ1.190716.003/1910071200:user/release-keys" | sudo tee -a /var/lib/waydroid/waydroid_base.prop
 

sync
sudo umount $MOUNT_DIR



sudo systemctl start waydroid-container




