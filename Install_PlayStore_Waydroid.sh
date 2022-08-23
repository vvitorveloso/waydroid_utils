#sudo pacman -S qemu
###DEBUG
sudo rm -rf /tmp/opengapps
###


waydroid session stop
sudo systemctl stop waydroid-container.service
sudo rm -rf /tmp/opengapps/

IMG=$(cat /var/lib/waydroid/waydroid.cfg | grep images_path | cut -d' ' -f 3)/system.img
IMG_VENDOR=$(cat /var/lib/waydroid/waydroid.cfg | grep images_path | cut -d' ' -f 3)/vendor.img
MOUNT_DIR=/tmp/waydroid_system
TMP_DIR=/tmp/opengapps/system/


ARCH=$(cat /var/lib/waydroid/lxc/waydroid/config | grep lxc.arch| cut -d " " -f 3)
VARIANT="pico"
ANDROID_VERSION="10.0"

while [ "$(mount | grep waydroid | cut -d" " -f3)" != "" ];do
for i in $(mount | grep waydroid | cut -d" " -f3);do sudo umount $i;done
echo retrying
sleep 1
done

mkdir $MOUNT_DIR


###############################
#HEAVLY BASED ON INSTALL PLAYSTORE ANBOX SCRIPT
# get latest releasedate based on tag_name for latest x86_64 build
OPENGAPPS_RELEASEDATE="$(curl -s https://api.github.com/repos/opengapps/x86_64/releases/latest | grep tag_name | grep -o "\"[0-9][0-9]*\"" | grep -o "[0-9]*")"
OPENGAPPS_FILE="open_gapps-$ARCH-$ANDROID_VERSION-$VARIANT-$OPENGAPPS_RELEASEDATE.zip"
OPENGAPPS_URL="https://sourceforge.net/projects/opengapps/files/x86_64/$OPENGAPPS_RELEASEDATE/$OPENGAPPS_FILE"

# get opengapps and install it
if [ ! -f ./$OPENGAPPS_FILE ]; then

wget $OPENGAPPS_URL -O "$OPENGAPPS_FILE"
fi 


echo "extracting open gapps"

#DEBUG
sudo rm -rf opengapps
unzip -d opengapps ./$OPENGAPPS_FILE

#DEBUG

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


#END DEBUG




##########Select and copy to tmp

DIRS="etc framework product lib64 lib app priv-app"
mkdir /tmp/opengapps
mkdir $TMP_DIR


 for i in $DIRS; do

	mkdir $TMP_DIR/$i
	#######DEBUG
	#find opengapps -name $i -type d -exec echo cp -aR $PWD/{}/ $TMP_DIR/ \; 
	find opengapps -name $i -type d -exec  cp -aR $PWD/{}/ $TMP_DIR/ \; 
	
 done

	find opengapps -name overlay -type d -exec echo cp -aR $PWD/{}/ $TMP_DIR/product/overlay/ \; 


#sudo chown 0:0 -R $TMP_DIR




############################################


mkdir /tmp/opengapps/system/bin/
mkdir /tmp/opengapps/system/addon.d/
mkdir /tmp/opengapps/system/etc/init/


##################################################


###############RESIZE

########################

SIZE=$(echo $(du -h -d0 /tmp/opengapps/system/  | cut -f1 | head -c -1))
G_OR_M=( ${SIZE: -1})

echo $SIZE
if [[ "$G_OR_M"  == "G" ]] ; then
	S_ADD=1
SIZE=$(echo $SIZE | cut -d"," -f1)
else
	S_ADD=100
fi
SIZE=$(echo $SIZE + $S_ADD |bc)
SIZE=$SIZE"$G_OR_M"
SIZE=$(echo $SIZE | sed 's/\./\,/g')
SIZE=$(echo $SIZE | sed 's/\,G/\G/g')
echo adding \+ $SIZE to system.img 
#debug
sudo qemu-img resize $IMG +$SIZE
sudo e2fsck -f $IMG
sudo resize2fs $IMG

# FROM Wachid (waydroid telegram) to add when i got time
# resize2fs /var/lib/waydroid/images/system.img $(($original_size+$needed_spaces))M

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

#sudo rm -rf  $MOUNT_DIR/system/priv-app/GooglePackageInstaller
sudo rm -rf  $MOUNT_DIR/system/priv-app/PackageInstaller



sudo chown 0:0 -R /tmp/opengapps/

##################
#MOVE TO IMG
#################

sudo cp -aR $TMP_DIR $MOUNT_DIR
#SPOOF
#echo ro.build.fingerprint="OnePlus/OnePlus7Pro_EEA/OnePlus7Pro:10/QKQ1.190716.003/1910071200:user/release-keys" | sudo tee -a /var/lib/waydroid/waydroid_base.prop

#wont start
sudo rm -rf  $MOUNT_DIR/system/priv-app/WellbeingPrebuilt


############



sync

while [ "$(mount | grep waydroid | cut -d" " -f3)" != "" ];do
for i in $(mount | grep waydroid | cut -d" " -f3);do sudo umount $i;done
echo retrying
sleep 1
done



sudo systemctl start waydroid-container
