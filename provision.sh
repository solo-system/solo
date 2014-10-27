#!/bin/bash

# We don't need to even think about p3 here, since we don't know what
# size it is.  Moreover we've now learned about re-reading the
# partition.  So all that is moved into normalboot.sh

# TODO:
# numbers on /etc/fstab entry for fsck
# hostname exists in the /etc/hosts file too!
# still get NOTICE: the software on this Raspberry Pi has not been fully configured
# we should turn off swap Adding 102396k swap on /var/swap
# howto shrink the ext2fs if we purge lots of crap (don't fear p3, cos it doesn't exist here)

echo
echo "------------------------------------------------"
echo " Welcome to the provisioner."
echo " This is run by hand on a freshly installed SBC"
echo " to add recorder functionality."
echo " See accompanying raspi-install.txt for more"
echo "------------------------------------------------"
echo 

if [ "$USER" != "root" ] ; then
    echo
    echo "Error: must be root - use \"sudo su\"."
    exit -1
fi

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


### Do things raspi-config would normally do: (timezone, hostname, i2c)
echo
echo "Doing raspi-config things..."
echo "  setting hostname..."
echo "recorder" > /etc/hostname
echo "  setting timezone"
echo "Europe/London" > /etc/timezone
dpkg-reconfigure -f noninteractive tzdata
echo "Done doing raspi-config-like things."
echo 


### Download and Install our code:
echo 
echo "Downloading our config scripts ..."
#scp -pr jdmc2@jdmc2.com:recorder/"{normalboot.sh,switchoff.py}" /root/
chmod +x /root/recorder/normalboot.sh /root/recorder/switchoff.py 
echo "Downloading and Installing amon ..."
#scp -pr jdmc2@jdmc2.com:code/amon/ /home/amon
( cd /home/amon/ ; git clone jdmc2@jdmc2.com:git/amon )
chown -R amon.amon /home/amon
chmod +x /home/amon/amon/amon #gosh - that's silly
echo "PATH=$PATH:/home/amon/amon/" > /home/amon/.bashrc
echo "Done downloading our software"
echo

#### Packages:
#apt-get update
apt-get -y purge fake-hwclock # wolfram-engine put it back
#apt-get -y upgrade
apt-get install i2c-tools bootlogd
 apt-get install emacs23-nox # while we are developing
#rpi-update


echo
echo "Adding normalboot.sh to rc.local"
sed -i 's:^exit 0$:/root/recorder/normalboot.sh >> /root/recorder/normalboot.log 2>\&1\n\n&:' /etc/rc.local
chmod +x /root/recorder/normalboot.sh
echo "Done updating rc.local"
echo

echo 
echo "setting up RTC"
echo "  un-blacklisting i2c-bcm2708"
sed -i 's:^blacklist i2c-bcm2708$:#&1:' /etc/modprobe.d/raspi-blacklist.conf
echo "  adding i2c-dev to /etc/modules"
echo "Done setting up RTC"

### Remove clutter, sync and exit.
rm -f /home/amon/pistore.desktop
sync
sync


### All done.
echo
echo "----------------------------------------------------------"
echo " provision.sh finished successfully."
echo " now poweroff, and take this image as the new install image"
echo " sudo dd bs=512 count=6400000 if=/dev/sdc of=recorder-fdate.img ; sync"
echo " where the count=XXX you can get from fdisk -l"
echo "----------------------------------------------------------"
echo 

exit 0
