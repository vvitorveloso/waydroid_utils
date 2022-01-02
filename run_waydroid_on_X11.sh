#sudo systemctl stop waydroid-container.service

#sudo ln -s  /dev/binderfs/anbox-binder /dev/binder
#sudo ln -s  /dev/binderfs/anbox-vndbinder /dev/vndbinder
#sudo ln -s  /dev/binderfs/anbox-hwbinder /dev/hwbinder

#sudo systemctl start waydroid-container.service

#waydroid session start

#############

#mutter --wayland --nested &
#sleep 5

echo '#!/bin/bash' > /tmp/waystart.sh
#echo XDG_SESSION_TYPE=wayland xterm >> /tmp/waystart.sh
echo XDG_SESSION_TYPE=wayland waydroid show-full-ui >> /tmp/waystart.sh

chmod +x /tmp/waystart.sh

kwin_wayland --xwayland --width 1336 --height 720  /tmp/waystart.sh
