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

[ $PWD != '/opt/solo' ] && { echo "must be in /opt/solo, not $PWD. Stopping."; exit -1; }

# are we 3.12 or 3.18 kernel (device tree or not?)
KRNL=$(uname -r | cut -f1,2 -d'.')
if [ $KRNL = "3.12" ] ; then
    DT=no
elif [ $KRNL = "3.18" ] ; then
    DT=yes
else
    DT=unknown
fi

echo "Detected KRNL version $KRNL, so assuming device tree is $DT"

QPURGE=unk
while [ $QPURGE != "yes" -a $QPURGE != "no" ] ; do
  echo "shall I purge unneeded packages (slow) ???"
  read QPURGE
done

echo "PURGE is $QPURGE"
echo 
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
chmod +x /opt/solo/solo-boot.sh /opt/solo/switchoff.py
echo "Downloading and Installing amon ..."
( cd /home/amon/ ; git clone jdmc2@jdmc2.com:git/amon.git )
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
CURRENT_HOSTNAME=`cat /etc/hostname | tr -d " \t\n\r"`
NEW_HOSTNAME="solo"
echo $NEW_HOSTNAME > /etc/hostname
sed -i "s/127.0.1.1.*$CURRENT_HOSTNAME/127.0.1.1\t$NEW_HOSTNAME/g" /etc/hosts


echo "Setting timezone ..."
echo "Europe/London" > /etc/timezone
dpkg-reconfigure -f noninteractive tzdata
echo "Done doing raspi-config-like things."
echo 

### Packages:

PURGE="fake-hwclock wolfram-engine xserver.* x11-.* xarchiver xauth xkb-data console-setup xinit lightdm lxde.* python-tk python3-tk scratch gtk.* libgtk.* openbox libxt.* lxpanel gnome.* libqt.* gvfs.* xdg-.* desktop.* freepats smbclient"


if [ $QPURGE = "yes" ] ; then
  echo "APT: purging unwanted packages..."
  apt-get -y purge $PURGE
  apt-get --yes autoremove
  apt-get --yes autoclean
  apt-get --yes clea
  echo "APT: Done purging unwanted packages..."
fi

### update and install things we need
### on second thoughts - this is NOT the right thing to do.
### I should trust the raspbian release to be correct, no need to update
### Just as there is no reason to run rpi-update.

### This makes solo rebuilds stable (within a raspbian release)
### vulnerable to external changes out of my control.  If I find
### specific packages need updating, then can do it here on a pkg by
### pkg basis. So... New policy - Dont do apt-get upgrade here.

NEWPKGS="i2c-tools bootlogd ntpdate rdate"
echo "APT: installing new packages: $NEWPKGS"
apt-get update
#apt-get -y upgrade
apt-get -y install $NEWPKGS
apt-get -y install emacs23-nox # ARGH this costs 60Mb.
# rpi-update #dont do this as it might muck things up
apt-get --yes autoremove
apt-get --yes autoclean
apt-get --yes clean
echo "APT: done installing new packages..."

echo
echo "Adding solo-boot.sh to rc.local"
sed -i 's:^exit 0$:/opt/solo/solo-boot.sh >> /opt/solo/solo-boot.log 2>\&1\n\n&:' /etc/rc.local
chmod +x /opt/solo/solo-boot.sh
echo "Done updating rc.local"
echo

echo
echo "Enabling i2c (for rtc) (see raspi-config for more details)"
if [ $DT = "yes" ] ; then
    printf "dtparam=i2c_arm=on\n" >> /boot/config.txt
else
    echo "KRNL suggests we're doing a cirrus install (old krnl), so configure that clock here"
    echo "Don't know how to do that yet"
    echo "TODO"
fi
    # there used to be stuff about un-blacklisting, but not needed any more 
echo "Done enabling i2c"

#echo
#echo "Adding heartbeat module..."
#echo "... updating /etc/modules with modprobe ledtrig_heartbeat"
#echo "ledtrig_heartbeat" >> /etc/modules
#echo "Done adding heartbeat module."
#echo

if [ $QPURGE ] ; then 
    ### Remove clutter, sync and exit.
    rm -f /home/amon/pistore.desktop
    #find  /var/log -type f -delete
    rm -f home/jdmc2/amon/amon.log

    ### Experimental removes - added 2015-02-10 by jdmc2.
    rm -rf /usr/share/{icons,doc,share,scratch,midi,fonts}
fi

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
