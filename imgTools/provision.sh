#!/bin/bash

# provision.sh: turn a stock raspbian img into a bootable "Solo
# Software Image".

# There should be NO mention of p3 here. It doesn't exist at the time
# of provisioning.

# show all commands on stdout.
set -x

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

# QPURGE=unk
QPURGE=yes
#QPURGE=no
if [ $QPURGE != "yes" -a $QPURGE != "no" ] ; then
  echo "provision.sh: ERROR: QPURGE must be yes or no - bailing out."
  exit -1
fi

echo "====================================================================="
echo "Provisioner is about to install solo with purge=$QPURGE"
echo "====================================================================="

### Splat solo.git files to the correct places:
chmod +x /opt/solo/solo-boot.sh
mkdir -v /boot/solo/
cp -v /opt/solo/boot/solo.conf /boot/solo/solo.conf # copy solo.conf into /boot/solo/

### Get and install amon:
mkdir /opt/git/
git -C /opt/git clone https://github.com/solosystem/amon.git # amon is now in /opt/amon/

#---------------BEGIN MOVE THIS BLOCK TO Makefile ----------------------
useradd -m amon -s /bin/bash
echo "amon:amon" | chpasswd
usermod -a -G adm,dialout,cdrom,kmem,sudo,audio,video,plugdev,games,users,netdev,input,gpio amon
echo "amon ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers
#---------------ENdD MOVE THIS BLOCK TO Makefile ----------------------

make -C /opt/git/amon install # install amon

echo "Done Installing amon"
echo

echo
echo "Doing raspi-config things"
echo "... setting hostname..."
CURRENT_HOSTNAME=`cat /etc/hostname | tr -d " \t\n\r"`
NEW_HOSTNAME="solo"
echo $NEW_HOSTNAME > /etc/hostname
sed -i "s/127.0.1.1.*$CURRENT_HOSTNAME/127.0.1.1\t$NEW_HOSTNAME/g" /etc/hosts

# set default timezone to Etc/UTC (overridden by solo.conf with SOLO_TZ)
ln -fs /usr/share/zoneinfo/Etc/UTC /etc/localtime
dpkg-reconfigure --frontend noninteractive tzdata

############# upgrade alsa ########################
# we need this upgrade because arecord (pre 1.1.6) limits high sample
# rates to 192000, which is no good for dodotronic mics.
# do this before package purge

UPGRADEALSA=yes
if [ $UPGRADEALSA = "yes" ] ; then
    echo "Upgrading ALSA support to version 1.1.6 ... (i am in $(pwd) )"
    f=upgrade-alsa.sh
    if [ -r $f ] ; then
	echo "Upgrading alsa using $f"
	./$f
	echo "Done upgrading alsa using $f"
    else
	echo "WARNING Can't find $f - no such readable file (I am in $(pwd))"
	exit -1
    fi
else
    echo "UPGRADEALSA=$UPGRADEALSA => so not upgrading using $f"
fi
####################### end of upgrading alsa #################


### Package management:
OLDPURGE="fake-hwclock wolfram-engine xserver.* x11-.* xarchiver xauth xkb-data console-setup xinit lightdm lxde.* python-tk python3-tk scratch gtk.* libgtk.* openbox libxt.* lxpanel gnome.* libqt.* gvfs.* xdg-.* desktop.* freepats smbclient"

# packages to remove, chosen by eye from debug by jdmc2 on : 2017-08-24
PURGE="aptitude aptitude-common geoip-database samba-common libraspberrypi-doc man-db manpages manpages-dev"

### packages I might regret removing...
#MIGHT_REGRET="libgl1-mesa-dri libflite1 libatlas3-base poppler-data fonts-freefont-ttf omxplayer fonts-droid libwibble-dev epiphany-browser-data gconf2-common libgconf-2-4 libxml2 gsfonts libsmbclient libxapian-dev dpkg-dev  libept-dev libfreetype6-dev libpng12-dev libtagcoll2-dev manpages-dev manpages libexif12 libopencv-core2.4 libdirectfb-1.2-9 jackd2 libaspell15 debian-reference-en libgstreamer-plugins-base0.10-0 libgstreamer-plugins-base1.0-0 libgstreamer0.10-0 libgstreamer1.0-0 penguinspuzzle fontconfig-config fontconfig libfontconfig1 libfontenc1 libfreetype6 libfreetype6-dev libxfont1 libxdmcp6 libxau6 libfontenc1 libmenu-cache1"

if [ $QPURGE = "yes" ] ; then
  echo "APT: purging unwanted packages..."
  apt-get -y purge $PURGE
#  apt-get -y purge $MIGHT_REGRET
  apt-get --yes autoremove
  apt-get --yes autoclean 
  apt-get --yes clean
  echo "APT: Done purging unwanted packages..."
else
  echo "NOT purging unwanted packages (since QPURGE is not yes)"
  #apt-get -y install emacs23-nox # ARGH this costs 60Mb.
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
# definetly get rid of fake-hwclock
apt-get -y purge fake-hwclock

# i2c-tools needed for clock investigations (although not in normal operation)
# exfat-utils probably needed to make ext partition on p3 (I think, but it could be a hangover from labelling partitons).
# need wiringpi for wittypi.
# need python3-pip for installing pyephem which in turn is needed by duskdawn().
NEWPKGS="i2c-tools exfat-utils wiringpi python3-pip"
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

echo "Installing pip package for python:"
pip install pyephem
pip install pytz
echo "Done:Installing pip package for python."

echo
echo "Adding solo-boot.sh to rc.local"
sed -i 's:^exit 0$:/opt/solo/solo-boot.sh >> /opt/solo/solo-boot.log 2>\&1\n\n&:' /etc/rc.local
chmod +x /opt/solo/solo-boot.sh
echo "Done updating rc.local"
echo

# enable udev to set the clock at boot time, when /dev/rtc0 comes to life:
sed -i "s:/run/systemd/system:/i/am/nonexistent:g"  /lib/udev/hwclock-set

echo  "Enabling i2c in kernel"

echo "adding i2c-dev to modules..." # needed by wittypi (wiringpi)
echo "i2c-dev" >> /etc/modules

printf "\n# lines added by solo's provision.sh:\n" >> /boot/config.txt

echo "... adding dtparm=i2c_arm=on to /boot/config.txt"
printf "dtparam=i2c_arm=on\n" >> /boot/config.txt

echo "... adding dtoverlay=i2c-rtc,ds3231 to /boot/config.txt"
printf "dtoverlay=i2c-rtc,ds3231\n" >> /boot/config.txt

echo "... adding dtoverlay=i2c-rtc,mcp7941x to /boot/config.txt"
printf "dtoverlay=i2c-rtc,mcp7941x\n" >> /boot/config.txt

echo "... not quite adding fe-pi-audio and i2s-mmap"
# see: https://fe-pi.com/p/support-and-setup
# dtoverlay=fe-pi-audio
# dtoverlay=i2s-mmap

echo  "Done: Enabling i2c in kernel"

# enable ssh after boot: (per raspban new policy 2017-08-10)
# still needed on (first stretch) img: 2017-08-16-raspbian-stretch-lite.img)
touch /boot/ssh

# speed up boot -> don't wait for a dhcpd address:
rm -fv /etc/systemd/system/dhcpcd.service.d/wait.conf

# setup software for Cirrus Logic Audio Card
#CLAC=no
CLAC=yes
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

# boot to systemd, not the init_resize nonsense:
sed -i 's| init=/usr/lib/raspi-config/init_resize.sh||' /boot/cmdline.txt

echo
echo "Remove a bunch of unnecessary cron jobs that do pointless things:"
rm -vf /etc/cron.daily/{dpkg,man-db,apt,passwd,aptitude,bsdmainutils,ntp} /etc/cron.weekly/man-db
echo "done removing pointelss cronjobs"
echo


# TODO: how many of these are still pertinent?
if [ $QPURGE = "yes" ] ; then
    echo "About to purge if required:"

    # this one is quite aggressive...
    find  /var/log -type f -delete 

    # man pages indexes:
    rm -rf /var/cache/man
    rm -rf /usr/share/man/
    
    rm -f home/jdmc2/amon/amon.log

    ### Experimental removes - added 2015-02-10 by jdmc2.
    rm -rf /usr/share/{icons,doc,share,scratch,midi,fonts}
    
    ### an example video:
    rm -rf /opt/vc/src/hello_pi/hello_video/test.h264

    rm -rf /var/lib/apt/lists/*
    
    apt-get -y clean

    ### purge all the RJ files we wget'd above.
    rm -rf /opt/solo/rj
     
    echo "Done purging files"
else
    echo "Not purging"
fi

DEBUG=no

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
    echo "DEBUG is not set, so not generating debug files"
fi

# How do we do this in a chroot properly - here we just abandon it. (does it matter?)
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
echo "----------------------------------------------------------"
echo

exit 0

