#!/bin/bash

# There should be NO mention of p3 here. It doesn't exist
# It should only do things that need internet access. 
# [ or are slow - I supose ]
# hostname = solo, user=amon, software = amon 
# directory = /opt/solo/

echo
echo "------------------------------------------------"
echo " Welcome to the provisioner."
echo " This is run by hand on a freshly installed SBC"
echo " to add solo functionality."
echo " See accompanying raspi-install.txt for more"
echo "------------------------------------------------"
echo 

if [ "$USER" != "root" ] ; then
    echo
    echo "Error: must be root - use \"sudo su\"."
    exit -1
fi

[ $PWD != '/opt/solo' ] && { echo "must be in /opt, not $PWD. Stopping."; exit -1; }

echo " *** Press return to continue ..."
read a

### Users:
echo
echo "Adding user amon..."
useradd -m amon
usermod -a -G adm,dialout,cdrom,kmem,sudo,audio,video,plugdev,games,users,netdev,input,gpio amon 
passwd amon
echo "amon ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers
echo "Done adding user amon (with groups and sudo powers)"
echo

### Download and Install our code:
echo 
echo "Preparing our boot scripts"
chmod +x /opt/solo/normalboot.sh /opt/solo/switchoff.py 
echo "Downloading and Installing amon ..."
( cd /home/amon/ ; git clone jdmc2@jdmc2.com:git/amon )
chown -R amon.amon /home/amon
chmod +x /home/amon/amon/amon # gosh - that's silly
echo "PATH=$PATH:/home/amon/amon/" > /home/amon/.bashrc
echo "Done downloading our software"
echo

echo " --------------------------------- "
echo " GO AWAY - I can do the rest myself"
echo " ----------------------------------"


### Do things raspi-config would normally do: (timezone, hostname, i2c)
echo
echo "Doing raspi-config things..."
echo "  setting hostname..."
echo "solo" > /etc/hostname
echo "  setting timezone"
echo "Europe/London" > /etc/timezone
dpkg-reconfigure -f noninteractive tzdata
echo "Done doing raspi-config-like things."
echo 

### Packages:

PURGE="fake-hwclock wolfram-engine xserver.* x11-.* xarchiver xauth xkb-data console-setup xinit lightdm lxde.* python-tk python3-tk scratch gtk.* libgtk.* openbox libxt.* lxpanel gnome.* libqt.* gvfs.* xdg-.* desktop.* freepats smbclient"
echo "APT: remove stuff we don't want, and installing things we do..."
apt-get -y purge $PURGE
apt-get --yes autoremove
apt-get --yes autoclean
apt-get --yes clean

### update and install things we need
apt-get update
apt-get -y upgrade
apt-get -y install i2c-tools bootlogd ntpdate rdate
apt-get -y install emacs23-nox # ARGH this costs 60Mb.
# rpi-update #dont do this as it mucks things up
apt-get --yes autoremove
apt-get --yes autoclean
apt-get --yes clean
echo "APT: done all the apt stuff and cleaned up"

echo
echo "Adding normalboot.sh to rc.local"
sed -i 's:^exit 0$:/opt/solo/normalboot.sh >> /opt/solo/normalboot.log 2>\&1\n\n&:' /etc/rc.local
chmod +x /opt/solo/normalboot.sh
echo "Done updating rc.local"
echo

echo 
echo "setting up RTC"
echo "  un-blacklisting i2c-bcm2708"
sed -i 's:^blacklist i2c-bcm2708$:#&1:' /etc/modprobe.d/raspi-blacklist.conf
echo "  adding i2c-dev to /etc/modules"
echo "WARNING - I don't actually do this, which is wierd - perhaps I should???"
echo "Done setting up RTC"

echo 
echo "Adding heartbeat module..."
echo "... updating /etc/modules with modprobe ledtrig_heartbeat"
echo "ledtrig_heartbeat" >> /etc/modules
echo "Done adding heartbeat module."
echo 


### Remove clutter, sync and exit.
rm -f /home/amon/pistore.desktop
sync
sync

### All done.
echo
echo "----------------------------------------------------------"
echo " provision.sh finished successfully."
echo " now poweroff, and take this image as the new install image"
echo " sudo dd bs=512 count=6400000 if=/dev/sdc of=solo-fdate.img ; sync"
echo " where the count=XXX you can get from fdisk -l"
echo "----------------------------------------------------------"
echo 

exit 0
