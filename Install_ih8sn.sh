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


rm -rf ih8sn-x86_64.zip 
wget https://github.com/luk1337/ih8sn/releases/download/latest/ih8sn-x86_64.zip

rm -rf ih8sn 
unzip -d ih8sn ih8sn-x86_64.zip 


SIZE=$(echo $(du -h -d0 ih8sn | cut -d'M' -f1 | cut -d',' -f1)M)

sudo qemu-img resize $IMG +$SIZE
sudo e2fsck -f $IMG
sudo resize2fs $IMG

sudo mount $IMG $MOUNT_DIR

sudo rm -rf $MOUNT_DIR/system/bin/ih8sn
sudo cp -a ./ih8sn/60-ih8sn.sh $MOUNT_DIR/system/addon.d/
sudo cp -a ./ih8sn/ih8sn $MOUNT_DIR/system/bin/
sudo cp -a ./ih8sn.conf  $MOUNT_DIR/system/etc/
sudo cp -a ./ih8sn/ih8sn.rc $MOUNT_DIR/system/etc/init/

echo ro.build.fingerprint="OnePlus/OnePlus7Pro_EEA/OnePlus7Pro:11/RKQ1.201022.002/2110211502:user/release-keys" | sudo tee -a /var/lib/waydroid/waydroid_base.prop
echo ro.build.description="OnePlus7Pro-user 11 RKQ1.201022.002 2110211502 release-keys" | sudo tee -a /var/lib/waydroid/waydroid_base.prop
echo ro.build.version.security_patch="2021-10-01" | sudo tee -a /var/lib/waydroid/waydroid_base.prop
echo ro.system.build.tags="release-keys" | sudo tee -a /var/lib/waydroid/waydroid_base.prop
echo ro.system.build.type="user" | sudo tee -a /var/lib/waydroid/waydroid_base.prop
echo ro.system.build.version.release="11" | sudo tee -a /var/lib/waydroid/waydroid_base.prop
### REVIEW 
#          def description(sec: str, p: Prop) -> str:
#              return f"{p[f'ro.{sec}.build.flavor']} {p[f'ro.{sec}.build.version.release_or_codename']} {p[f'ro.{sec}.build.id']} {p[f'ro.{sec}.build.version.incremental']} {p[f'ro.{sec}.build.tags']}"
#          def fingerprint(sec: str, p: Prop) -> str:
#              return f"""{p[f"ro.product.{sec}.brand"]}/{p[f"ro.product.{sec}.name"]}/{p[f"ro.product.{sec}.device"]}:{p[f"ro.{sec}.build.version.release"]}/{p[f"ro.{sec}.build.id"]}/{p[f"ro.{sec}.build.version.incremental"]}:{p[f"ro.{sec}.build.type"]}/{p[f"ro.{sec}.build.tags"]}"""

#              p["ro.build.description"] = description(sec, p)
#              p[f"ro.build.fingerprint"] = fingerprint(sec, p)
###              p[f"ro.{sec}.build.description"] = description(sec, p)
#              p[f"ro.{sec}.build.fingerprint"] = fingerprint(sec, p)
#              p[f"ro.bootimage.build.fingerprint"] = fingerprint(sec, p)


sync
sudo umount $MOUNT_DIR



sudo systemctl start waydroid-container




