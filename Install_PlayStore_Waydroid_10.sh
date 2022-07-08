#sudo pacman -S qemu
rm -rf ./opengapps/
sudo rm -rf /tmp/opengapps


#ZERO_BINS >>>> find /proc/sys/fs/binfmt_misc -type f -name 'arm*' -exec sudo sh -c 'echo -1 > {}' \;

waydroid session stop
sudo systemctl stop waydroid-container.service

IMG=$(cat /var/lib/waydroid/waydroid.cfg | grep images_path | cut -d' ' -f 3)/system.img
IMG_VENDOR=$(cat /var/lib/waydroid/waydroid.cfg | grep images_path | cut -d' ' -f 3)/vendor.img
MOUNT_DIR=/tmp/waydroid_system
TMP_DIR=/tmp/opengapps/system/

while [[ $(echo $(mount | grep waydroid)) != "" ]] ;do
for i in $(mount | grep waydroid | cut -d " " -f1) ;do 
sudo umount $i 
done
done

mkdir $MOUNT_DIR


###############################
#HEAVLY BASED ON INSTALL PLAYSTORE ANBOX SCRIPT
# get latest releasedate based on tag_name for latest x86_64 build
OPENGAPPS_RELEASEDATE="$(curl -s https://api.github.com/repos/opengapps/x86_64/releases/latest | grep tag_name | grep -o "\"[0-9][0-9]*\"" | grep -o "[0-9]*")"
OPENGAPPS_FILE="open_gapps-x86_64-10.0-pico-$OPENGAPPS_RELEASEDATE.zip"
OPENGAPPS_URL="https://sourceforge.net/projects/opengapps/files/x86_64/$OPENGAPPS_RELEASEDATE/$OPENGAPPS_FILE"

# get opengapps and install it
if [ ! -f ./$OPENGAPPS_FILE ]; then

wget $OPENGAPPS_URL -O "$OPENGAPPS_FILE"
fi 


echo "extracting open gapps"


sudo rm -rf opengapps

unzip -d opengapps ./$OPENGAPPS_FILE


for filename in ./opengapps/Core/*.tar.lz
do
    tar --lzip -xvf $filename -C ./opengapps/Core/
done

for filename in ./opengapps/GApps/*.tar.lz
do
    tar --lzip -xvf $filename -C ./opengapps/GApps/
done


for filename in ./opengapps/Optional/*.tar.lz
do
    tar --lzip -xvf $filename -C ./opengapps/Optional/
done







##########Select and copy to tmp

DIRS="etc framework product lib64 app priv-app"
mkdir /tmp/opengapps
mkdir $TMP_DIR


 for i in $DIRS; do

	mkdir $TMP_DIR/$i
 	find opengapps -name $i -type d -exec  cp -aR $PWD/{}/ $TMP_DIR/ \; 
	
 done


#sudo chown 0:0 -R $TMP_DIR




############################################


mkdir /tmp/opengapps/system/bin/
mkdir /tmp/opengapps/system/addon.d/
mkdir /tmp/opengapps/system/etc/init/
sudo cp -a ./ih8sn/60-ih8sn.sh /tmp/opengapps/system/addon.d/
sudo cp -a ./ih8sn/ih8sn /tmp/opengapps/system/bin/
sudo cp -a ./ih8sn.conf  /tmp/opengapps/system/etc/
sudo cp -a ./ih8sn/ih8sn.rc /tmp/opengapps/system/etc/init/

##################################################


###############RESIZE

########################

SIZE=$(echo $(du -h -d0 /tmp/opengapps/system/ | cut -d'M' -f1)) 
SIZE=$(( $SIZE + 10 ))
SIZE=$SIZE\M
echo adding \+ $SIZE to system.img 
sudo qemu-img resize $IMG +$SIZE
sudo e2fsck -f $IMG
sudo resize2fs $IMG

sudo mount $IMG $MOUNT_DIR



###REMOVE MICROG

for i in $(sudo find $MOUNT_DIR | grep apk | grep -i microg); do sudo rm $i;done
sudo find /tmp/waydroid_system -name com.google.android.gsf -exec rm -rf {} \;
sudo find /tmp/waydroid_system -name com.android.vending -exec rm -rf {} \;
sudo find /tmp/waydroid_system -name com.google.android.gms -exec rm -rf {} \;
APPS="PrebuiltGmsCore GoogleServicesFramework Phonesky GoogleExtServices GoogleExtShared"
for i in $APPS; do sudo rm -rf /tmp/waydroid_system/system/priv-app/$i*;done
##
######################


###########
#REMOVE OLD, view perms later
####################

sudo rm -rf  $MOUNT_DIR/system/priv-app/GooglePackageInstaller
sudo rm -rf  $MOUNT_DIR/system/priv-app/PackageInstaller


##################
#MOVE TO IMG
#################

sudo cp -aR $TMP_DIR $MOUNT_DIR

echo ro.build.fingerprint="OnePlus/OnePlus7Pro_EEA/OnePlus7Pro:10/QKQ1.190716.003/1910071200:user/release-keys" | sudo tee -a /var/lib/waydroid/waydroid_base.prop



############



sync
sudo umount $IMG



sudo systemctl start waydroid-container

git clone https://github.com/casualsnek/waydroid_script
echo now run "$"sudo waydroid_script/waydroid_extras.py -n to libndk
