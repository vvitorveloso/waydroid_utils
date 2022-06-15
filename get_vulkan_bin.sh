cd BlissOS

X=$(sudo find mount | grep -i vulkan)
sudo rm -rf ../out/
sudo rm -rf ../vulkan/
for i in $X; do 
	mkdir -p ../out/$(dirname $i) 
	sudo cp -aR $i ../out/$(dirname $i)
	echo $i ; done

sudo mv ../out/mount/system ../vulkan
sudo rm -rf ../out/