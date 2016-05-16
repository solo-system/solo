#!/bin/bash

# provision.sh: turn a stock raspbian img into a bootable "Solo
# Software Image".  see raspi-install.txt for more info.

# Notes:
# There should be NO mention of p3 here. It doesn't exist
# Anything needing internet access must be done here.
# Anything slow should be done too
# Install base is : directory = /opt/solo/

# log to console AND to logfile.
exec > >(tee "/opt/solo/provision.log") 2>&1


echo
echo "------------------------------------------------"
echo " Welcome to the provisioner. Running at $(date)"
echo " This is run by hand on a freshly installed SBC"
echo " to add solo functionality."
echo " See accompanying raspi-install.txt for more"
echo " exec'd so log is kept in /opt/solo/provision.log"
echo "------------------------------------------------"
echo

if [ "$USER" != "root" ] ; then
    echo
    echo "Error: must be root - use \"sudo su\"."
    exit -1
fi

[ $PWD != '/opt/solo' ] && { echo "must be in /opt/solo, not $PWD. Stopping."; exit -1; }

if [ ! -r /opt/solo/utils.sh ] ; then
    echo "Error: can't read /opt/solo/utils.sh - this is probably bad news!"
fi
source /opt/solo/utils.sh

# check we have enough disk free... (in Mbytes)
diskfree=`df -BM / | tail -1 | awk '{print $4}' | sed 's:M::g'`
if [ $diskfree -lt 100 ] ; then
    df -h /
    echo "Error - not enough free disk space - exiting (try rm -rf /home/pi/Music)"
    exit -1
fi


# CLAC=unk
CLAC=yes
while [ $CLAC != "yes" -a $CLAC != "no" ] ; do
  echo "Include support for Cirrus Logic Audio Card?"
  read CLAC
done

# QPURGE=unk
QPURGE=no
while [ $QPURGE != "yes" -a $QPURGE != "no" ] ; do
  echo "Minimize img size by purging unnecessary packages? (slower)"
  read QPURGE
done
echo "PURGE is $QPURGE"

echo "====================================================================="
echo "Provisioner is about to install solo with purge=$QPURGE and CLAC=$CLAC"
echo " *** Press return to continue ..."
# read a
echo "And we're off..."
echo " -----------------------------------"
echo " -----------------------------------"
echo " GO AWAY - I can do the rest myself."
echo " -----------------------------------"
echo " -----------------------------------"


add_user # add user amon, add to groups, enable sudo


### Download and Install our code:
echo 
echo "Preparing our boot scripts"
chmod +x /opt/solo/solo-boot.sh /opt/solo/switchoff.py
echo "Installing amon ..."
( cd /home/amon/ ; git clone https://github.com/solosystem/amon.git )
cp /opt/solo/asoundrc /home/amon/.asoundrc    # copy asoundrc into amon's home
cp /opt/solo/boot/amon.conf /boot/amon.conf    # need this on /boot partition
cp /opt/solo/boot/solo.conf /boot/solo.conf    # need this on /boot partition
chown -R amon.amon /home/amon
chmod +x /home/amon/amon/amon # gosh - that's silly
echo "PATH=$PATH:/home/amon/amon/" >> /home/amon/.bashrc
echo "Done Installing amon"
echo

echo
echo "Doing raspi-config things"
echo "... setting hostname..."
CURRENT_HOSTNAME=`cat /etc/hostname | tr -d " \t\n\r"`
NEW_HOSTNAME="solo"
echo $NEW_HOSTNAME > /etc/hostname
sed -i "s/127.0.1.1.*$CURRENT_HOSTNAME/127.0.1.1\t$NEW_HOSTNAME/g" /etc/hosts

echo 
echo "Setting timezone to Etc/UTC - it will be overridden in solo.conf with SOLO_TZ)"
echo "Etc/UTC" > /etc/timezone
dpkg-reconfigure -f noninteractive tzdata
echo "Done doing raspi-config-like things."


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

# need exfat-utils for doslabel command below (not needed on solo, just to rename the partition in the img)

NEWPKGS="i2c-tools bootlogd ntpdate rdate exfat-utils"
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

echo
echo "Adding solo-boot.sh to rc.local"
sed -i 's:^exit 0$:/opt/solo/solo-boot.sh >> /opt/solo/solo-boot.log 2>\&1\n\n&:' /etc/rc.local
chmod +x /opt/solo/solo-boot.sh
echo "Done updating rc.local"
echo

setup_rtc
enable_i2c

# setup software for Cirrus Logic Audio Card
if [ $CLAC = "yes" ] ; then
    echo "Installing support for CLAC..."
    #f=setup-clac.sh
    f=setup-clac-HiassofT.sh
    echo "sourcing $f"
    if [ -r $f ] ; then
	. $f
	echo "Done installing CLAC software"
    else
	echo "WARNING Can't source $f - no such readable file"
	exit -1
    fi
else
    echo "CLAC=$CLAC => so not sourcing setup-clac.sh"
fi

if [ $QPURGE = "yes" ] ; then
    echo "About to purge if required:"

    ### Remove clutter, sync and exit.
    rm -f /home/amon/pistore.desktop

    # this one is quite aggressive...
    find  /var/log -type f -delete 
    
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

    apt-get -y clean

    ### purge all the RJ files we wget'd above.
    rm -rf /opt/solo/rj
     
    echo "Done purging files"
else
    echo "Not purging"
fi

if [ "$DEBUG" = "yes" ] ; then
    echo "Generating some debug files..."
    debug_dir=/opt/solo/provision-debuglog/
    mkdir $debug_dir
    find  / -ls 2> /dev/null | sort -n -k7 > $debug_dir/filelist.txt
    dpkg -l > $debug_dir/installed-packages.txt
    du -sk / 2> /dev/null | sort -n > $debug_dir/diskusage-level0.txt
    du -sk /* 2> /dev/null | sort -n > $debug_dir/diskusage-level1.txt
    du -sk /*/* 2> /dev/null | sort -n > $debug_dir/diskusage-level2.txt
    du -sk /*/*/* 2> /dev/null | sort -n > $debug_dir/diskusage-leve3.txt
    dpkg-query -Wf '${Installed-Size}\t${Package}\n' | sort -n > $debug_dir/biggest-packages.txt
    echo "copy all debug: scp -prv $debug_dir jdmc2@t510j:solo-debug"
    echo "Done generating debug files - see $debug_dir"
else
    echo "DEBIG is not set, so not generating debug files"
fi

# do this last cos we need to unmount /boot to label it.
# provisioning in a chroot doesn't allow this.  So make it conditional.
# how do we detect a chroot environment?  look in /proc - there's nothing there if it's a chroot:

echo
echo "Labeling file system partitions nicely..."
if [ $(ls /proc | wc -l) -gt 0 ] ; then
    sync ; sync # old habits
    umount /boot
    dosfslabel /dev/mmcblk0p1 soloboot
    e2label /dev/mmcblk0p2 solo-sys
    sync ; sync;
else
    echo "NOT labeling file systems, because we are in a chroot"
fi
echo "Done Labeling file system partitions nicely..."
echo

### All done.
echo
echo "----------------------------------------------------------"
echo " provision.sh finished successfully."
echo " # poweroff"
echo " then carry this SD card to PC and:"
echo " sudo dd bs=512 count=XXXX if=/dev/sdX of=solo-fdate-bloated.img ; sync"
echo " where the count=XXX you can get from fdisk -l"
echo "----------------------------------------------------------"
echo

exit 0
