#!/bin/bash

# provision.sh: turn a stock raspbian img into a bootable "Solo
# Software Image"

# Notes:
# There should be NO mention of p3 here. It doesn't exist
# Anything needing internet access must be done here.
# Anything slow should be done too
# Install base is : directory = /opt/solo/

# log to console AND to logfile.
exec > >(tee "/opt/solo/provision.log") 2>&1

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

# check we have enough disk free... (in Mbytes)
diskfree=`df -BM / | tail -1 | awk '{print $4}' | sed 's:M::g'`
if [ $diskfree -lt 200 ] ; then
    df -h /
    echo "Error - not enough free disk space - exiting (try rm -rf /home/pi/Music)"
    exit -1
fi

# are we 3.12 or 3.18 kernel (device tree or not?)
#KRNL=$(uname -r | cut -f1,2 -d'.')
#if [ $KRNL = "3.12" ] ; then
#    DT=no
#elif [ $KRNL = "3.18" ] ; then
DT=yes # NO OLD KERNELS ANY MORE since Ragnar Jensen provided 3.18 based CLAC.img.
#else
#    DT=unknown
#fi
#echo "OLD: Detected KRNL version $KRNL, so assuming device tree is $DT"

CLAC=unk
while [ $CLAC != "yes" -a $CLAC != "no" ] ; do
  echo "Include Ragnar-Jensen's CLAC support?"
  read CLAC
done
#if [ $CLAC = "yes" ] ; then
#    echo "getting ragnar jensen's kernel.tar.gz package..."
# using his entire img, rather than just the kernel tarfile. (it didn't work - 
# perhaps because I was doing all the  other "solo" things - perhaps because there was no internet connection, perhaps because I was using an older (jan 2015, not feb 2015) version of stock raspbian.  OOPS or perhaps it was because I mis-spelled the "ldo1" for "ldol" below in the softdep: bit (now fixed).
#    RJ=/opt/solo/kernel_3_18_9_W_CL.tgz
#    scp jdmc2@t510j:raspi/ragnar-jensen/kernel_3_18_9_W_CL.tgz $RJ
#    echo "Done"
#fi

QPURGE=unk
while [ $QPURGE != "yes" -a $QPURGE != "no" ] ; do
  echo "Minimize img size by purging unnecessarry packages? (slower)"
  read QPURGE
done
echo "PURGE is $QPURGE"

echo "====================================================================="
echo "Provisioner is about to install solo with purge=$QPURGE and CLAC=$CLAC"
echo " *** Press return to continue ..."
read a

echo "And we're off..."


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
cp /opt/solo/asoundrc /home/amon/.asoundrc
cp /opt/solo/bootamon.conf /boot/amon.conf
chown -R amon.amon /home/amon
chmod +x /home/amon/amon/amon # gosh - that's silly
echo "PATH=$PATH:/home/amon/amon/" > /home/amon/.bashrc
echo "Done downloading our software"
echo

echo " -----------------------------------"
echo " -----------------------------------"
echo " GO AWAY - I can do the rest myself."
echo " -----------------------------------"
echo " -----------------------------------"

echo
echo "Labeling file system partitions nicely..."
e2label /dev/mmcblk0p1 soloboot
e2label /dev/mmcblk0p2 solosys
echo "Done Labeling file system partitions nicely..."

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

### Package management:
PURGE="fake-hwclock wolfram-engine xserver.* x11-.* xarchiver xauth xkb-data console-setup xinit lightdm lxde.* python-tk python3-tk scratch gtk.* libgtk.* openbox libxt.* lxpanel gnome.* libqt.* gvfs.* xdg-.* desktop.* freepats smbclient"

### packages I might regret removing...
MIGHT_REGRET="libgl1-mesa-dri libflite1 libatlas3-base poppler-data fonts-freefont-ttf omxplayer fonts-droid libwibble-dev epiphany-browser-data gconf2-common libgconf-2-4 libxml2 gsfonts libsmbclient libxapian-dev dpkg-dev  libept-dev libfreetype6-dev libpng12-dev libtagcoll2-dev manpages-dev manpages libexif12 libopencv-core2.4 libdirectfb-1.2-9 jackd2 libaspell15 debian-reference-en libgstreamer-plugins-base0.10-0 libgstreamer-plugins-base1.0-0 libgstreamer0.10-0 libgstreamer1.0-0 penguinspuzzle fontconfig-config fontconfig libfontconfig1 libfontenc1 libfreetype6 libfreetype6-dev libxfont1 libxdmcp6 libxau6 libfontenc1 libmenu-cache1"

if [ $QPURGE = "yes" ] ; then
  echo "APT: purging unwanted packages..."
  apt-get -y purge $PURGE 
  apt-get -y purge $MIGHT_REGRET # no reason for different line...
  apt-get --yes autoremove
  apt-get --yes autoclean
  apt-get --yes clean
  echo "APT: Done purging unwanted packages..."
else
  echo "NOT purging unwanted packages (since QPURGE is not yes)"
  echo "Instead, installing emacs"
  apt-get -y install emacs23-nox # ARGH this costs 60Mb.
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

# enable i2c in kernel (see raspi-config for more details)
echo "Enabling i2c (for rtc and clac) in /boot/config.txt"
printf "dtparam=i2c_arm=on\n" >> /boot/config.txt
echo "Done enabling i2c"
echo 

#echo
#echo "Adding heartbeat module..."
#echo "... updating /etc/modules with modprobe ledtrig_heartbeat"
#echo "ledtrig_heartbeat" >> /etc/modules
#echo "Done adding heartbeat module."
#echo

# This is useful if you are using his tarball (that unpacks on top of stock raspbian, but not if you use his image, as he's done it for you. so disable for the moment with ""
if [ "" -a  $CLAC = "yes" ] ; then
    echo 
    echo "Installing Ragnar Jensen's CLAC stuff..."
    pushd /
    tar xzf $RJ 
    popd
    echo "  ...Updating /boot/config.txt"
    cp /boot/config.txt /boot/config.txt.pre-provision
    echo "" >> /boot/config.txt
    echo "# Below added by solo's provision.sh" >> /boot/config.txt
    echo "dtparam=spi=on" >> /boot/config.txt
#    echo "dtparam=i2c_arm=on" >> /boot/config.txt WE ALREADY DID THIS.
    echo "dtoverlay=rpi-cirrus-wm5102-overlay" >> /boot/config.txt
    echo "kernel=kernel_CL.img" >> /boot/config.txt
    echo "  ...Updating /etc/modprobe.d/raspi-blacklist.conf"
    cp /etc/modprobe.d/raspi-blacklist.conf /etc/modprobe.d/raspi-blacklist.conf.pre-provision
    echo "# lines below added by solo's provision.sh" >> /etc/modprobe.d/raspi-blacklist.conf
    echo "softdep arizona-spi pre: arizona-ldo1" >> /etc/modprobe.d/raspi-blacklist.conf
    echo "softdep spi-bcm2708 pre: fixed" >> /etc/modprobe.d/raspi-blacklist.conf
    echo "Done Installing Ragnar Jensen's CLAC stuff..."
    echo
else
    echo "Done NOT enabling ragnar jensen's stuff"
fi

echo "About to purge if required:"

if [ $QPURGE = "yes" ] ; then 
    echo "purging files..."

    ### Remove clutter, sync and exit.
    rm -f /home/amon/pistore.desktop
    #find  /var/log -type f -delete
    rm -f home/jdmc2/amon/amon.log

    ### Experimental removes - added 2015-02-10 by jdmc2.
    rm -rf /usr/share/{icons,doc,share,scratch,midi,fonts}
    
    ### Cirrus logic put example flac files in /home/pi - purge them
    rm -rf /home/pi/*.flac 

    ### python games in /home/pi should go too:
    rm -rf /home/pi/python_games 

    ### and Music folder 
    rm -rf /home/pi/Music
    
    ### an example video:
    rm -rf /opt/vc/src/hello_pi/hello_video/test.h264

    echo "Done purging files"
fi

DEBUG=yes
if [ $DEBUG ] ; then
    echo "Generating some debug files..."
    debug_dir=/opt/solo/debug/
    mkdir $debug_dir
    find  / -ls | sort -n -k7 > $debug_dir/filelist.txt
    dpkg -l > $debug_dir/installed-packages.txt
    du -sk / | sort -n > $debug_dir/diskusage-level0.txt
    du -sk /* | sort -n > $debug_dir/diskusage-level1.txt
    du -sk /*/* | sort -n > $debug_dir/diskusage-level2.txt
    du -sk /*/*/* | sort -n > $debug_dir/diskusage-leve3.txt
    dpkg-query -Wf '${Installed-Size}\t${Package}\n' | sort -n > $debug_dir/biggest-packages.txt
    echo "copy all debug: scp -prv $debug_dir jdmc2@t510j:solo-debug"
    echo "Done generating debug files - see $debug_dir"
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
