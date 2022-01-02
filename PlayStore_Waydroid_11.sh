#sudo pacman -S qemu

#ZERO_BINS >>>> find /proc/sys/fs/binfmt_misc -type f -name 'arm*' -exec sudo sh -c 'echo -1 > {}' \;


waydroid session stop
sudo systemctl stop waydroid-container.service

IMG=/var/lib/waydroid/images/system.img
HOUDINI=/tmp/houdini
MOUNT_DIR=/tmp/waydroid_system
LIB=$MOUNT_DIR/system/lib64/arm64


mkdir $MOUNT_DIR
#
#cp $IMG $IMG.`date +"%d-%m-%Y"-%H-%M-%S`.NO_PLAYSTORE

###############################
#HEAVLY BASED ON INSTALL PLAYSTORE ANBOX SCRIPT
# get latest releasedate based on tag_name for latest x86_64 build
OPENGAPPS_RELEASEDATE="$(curl -s https://api.github.com/repos/opengapps/x86_64/releases/latest | grep tag_name | grep -o "\"[0-9][0-9]*\"" | grep -o "[0-9]*")"
OPENGAPPS_FILE="open_gapps-x86_64-11.0-pico-$OPENGAPPS_RELEASEDATE.zip"
OPENGAPPS_URL="https://sourceforge.net/projects/opengapps/files/x86_64/$OPENGAPPS_RELEASEDATE/$OPENGAPPS_FILE"

# get opengapps and install it
if [ ! -f ./$OPENGAPPS_FILE ]; then

wget $OPENGAPPS_URL -O "$OPENGAPPS_FILE"
fi 


echo "extracting open gapps"
########################

SIZE=$(echo $(du -h opengapps/Core -s | cut -d'M' -f1)M) 

###
#issues with autosize
SIZE=400M
##
sudo qemu-img resize $IMG +$SIZE
sudo e2fsck -f $IMG
sudo resize2fs $IMG

sudo mount $IMG $MOUNT_DIR

##################
###REMOVE MICROG

for i in $(sudo find $MOUNT_DIR | grep apk | grep microg); do sudo rm $i;done
sudo find /tmp/waydroid_system -name com.google.android.gsf -exec rm -rf {} \;
sudo find /tmp/waydroid_system -name com.android.vending -exec rm -rf {} \;
sudo find /tmp/waydroid_system -name com.google.android.gms -exec rm -rf {} \;

##
######################
sudo rm -rf opengapps

unzip -d opengapps ./$OPENGAPPS_FILE

for filename in ./opengapps/Core/*.tar.lz
do
    tar --lzip -xvf $filename -C ./opengapps/Core/
done

APPS="PrebuiltGmsCore GoogleServicesFramework Phonesky GoogleExtServices GoogleExtShared"

for i in $APPS;do

sudo cp -r $(find ./opengapps/ -type d -name "$i") $MOUNT_DIR/system/priv-app
done 


for i in $APPS;do
sudo chown -R 0:0 $MOUNT_DIR/system/priv-app/$i
done 

#PlayStoreOverlay ???


###########################################
########PERMISSION


sudo cp -r $(find ./opengapps/ -type f -name "privapp-permissions-google.xml") $MOUNT_DIR/system/etc/permissions/

############################################


#rm -rf ./opengapps/

sync
sudo umount $MOUNT_DIR



sudo systemctl start waydroid-container


echo now run "$"sudo waydroid_script/waydroid_extras.py -i