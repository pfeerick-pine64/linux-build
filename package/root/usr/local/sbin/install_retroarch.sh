#!/bin/bash

#check for root
if [ "$(id -u)" -ne "0" ]; then
	echo "This script requires root."
	exit 1
fi

#echo commands and arguments, and exit if any command returns non-zero status
set -xe

#add repositories and update
add-apt-repository ppa:libretro/testing -y
apt-add-repository -y ppa:ayufan/pine64-ppa -y
apt-get update -y

#Installs x for retroarch to run in
apt-get install x-window-system xterm twm -y

#Necessary dependencies
apt-get install libsdl1.2-dev libsdl1.2debian pkg-config build-essential -y

#Adds libretro and installs retroarch
apt-get install retroarch* libretro* -y

#Adds aufan's ppa for armsoc and libmali
apt-get install -y xserver-xorg-video-armsoc-sunxi libmali-sunxi-utgard0-r6p0

#enable autologin
mkdir -pv /etc/systemd/system/getty@tty1.service.d/
cat > /etc/systemd/system/getty@tty1.service.d/autologin.conf <<EOF
[Service]
ExecStart=
ExecStart=-/sbin/agetty --autologin pine64 --noclear %I 38400 linux
EOF
systemctl enable getty@tty1.service

#Autostart retroarch on login
cat > /etc/profile.d/10-start-retroarch.sh <<EOF
# autolaunch retroarch if not serial console login
if [ -z "\$DISPLAY" ] && [ "\$(tty)" != "/dev/ttyS0" ]; then
echo -e "\n\nRetroarch will start momentarily...\n\n"
sleep 2
startx retroarch
fi
EOF
chmod +x /etc/profile.d/10-start-retroarch.sh

#change hostname (will also update motd banner)
echo "retroarch" > /etc/hostname
sed -i "s/pine64/retroarch/g" /etc/hosts

#retropie header
cat > /etc/update-motd.d/05-figlet <<EOF
#!/bin/sh
figlet \$(hostname)
EOF
chmod +x /etc/update-motd.d/05-figlet

#hide other MOTD banners
chmod -x /etc/update-motd.d/00-header
chmod -x /etc/update-motd.d/10-help-text
chmod -x /etc/update-motd.d/11-pine-a64-help-text

#prevent any tty permission X.org errors
usermod pine64 -aG tty

#allow passwordless shutdown
pine64 ALL=(ALL) NOPASSWD: /sbin/poweroff, /sbin/reboot, /sbin/shutdown

#backup stock default config and customise
DEFAULT_CFG="/etc/retroarch.cfg"
cp ${DEFAULT_CFG} /etc/retroarch.cfg.stock
sed -i '/# video_fullscreen = false/c\video_fullscreen = true' ${DEFAULT_CFG}

#Sets up SMB sharefolder for ROMs and BIOS
mkdir -pv /home/pine64/ROMs
chown nobody:nogroup -R /home/pine64/ROMs
 
echo "[ROMs]
comment = ROMs Folder
path = /home/pine64/ROMs
writeable = yes
browseable = yes
guest ok = yes
create mask = 0644
directory mask = 2777
" >> /etc/samba/smb.conf

#Enables mali + drm
exec /usr/local/sbin/pine64_enable_sunxidrm.sh

exit 0
