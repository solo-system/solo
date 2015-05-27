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

RJCLAC=unk
while [ $RJCLAC != "yes" -a $RJCLAC != "no" ] ; do
  echo "Include Ragnar Jensen's debs for CLAC (Cirrus Logic Audio Card) support?"
  read RJCLAC
done

QPURGE=unk
while [ $QPURGE != "yes" -a $QPURGE != "no" ] ; do
  echo "Minimize img size by purging unnecessary packages? (slower)"
  read QPURGE
done
echo "PURGE is $QPURGE"

echo "====================================================================="
echo "Provisioner is about to install solo with purge=$QPURGE and CLAC=$RJCLAC"
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
echo "Adding solo-boot.sh to rc.local"
sed -i 's:^exit 0$:/opt/solo/solo-boot.sh >> /opt/solo/solo-boot.log 2>\&1\n\n&:' /etc/rc.local
chmod +x /opt/solo/solo-boot.sh
echo "Done updating rc.local"
echo

echo

# enable i2c in kernel (see raspi-config for more details)
echo "Enabling i2c (for rtc (and clac)) in /boot/config.txt"
printf "dtparam=i2c_arm=on\n" >> /boot/config.txt
echo "Done enabling i2c"
echo 

#echo
#echo "Adding heartbeat module..."
#echo "... updating /etc/modules with modprobe ledtrig_heartbeat"
#echo "ledtrig_heartbeat" >> /etc/modules
#echo "Done adding heartbeat module."
#echo


# OK - I just wrote the below code to install the CLAC support:
# comments:
# 1) it's a real mess having to pick these bits from idfferent places
# 2) Most of this ought to be part of the "amon" package (or atleast
# in the amon directory).

if [ $RJCLAC = "yes" ] ; then
    echo 
    echo "Installing Ragnar Jensen's CLAC stuff..."

    mkdir /opt/solo/rj/
    pushd /opt/solo/rj/

    # Step 1 : get the debs and unpack.
    # They live here: 
    # Normal : https://drive.google.com/uc?export=download&id=0BzIaxMH3N5O1OGNpYl8wRVhqbU0
    # Raspiv2: https://drive.google.com/uc?export=download&id=0BzIaxMH3N5O1S1JyTkJ4Z090cHc
    # but I've kept a local copy in:
    echo "... fetching CLAC debs"
    wget jdmc2.com/rjdebs/linux-image-3.18.9cludlmmapfll_3.18.9cludlmmapfll-3_armhf.deb
    wget jdmc2.com/rjdebs/linux-image-3.18.9-v7cludlmmapfll_3.18.9-v7cludlmmapfll-4_armhf.deb
    # They should be md5sum: 
    # b7947af7cbeb34d2d0324c6896aedf67  linux-image-3.18.9cludlmmapfll_3.18.9cludlmmapfll-3_armhf.deb
    # b168d2d736974f1f681fdefa9e246909  linux-image-3.18.9-v7cludlmmapfll_3.18.9-v7cludlmmapfll-4_armhf.deb

    echo "... installing debs"
    dpkg -i linux-image-3.18.9-v7cludlmmapfll_3.18.9-v7cludlmmapfll-4_armhf.deb
    dpkg -i linux-image-3.18.9cludlmmapfll_3.18.9cludlmmapfll-3_armhf.deb
    
    # get the older tarball, containing the DTS and the control scripts:
    wget jdmc2.com/rjdebs/kernel_3_18_9_W_CL.tgz # older versino of it all (debs superscede, but don't have dts.)
    tar xfz kernel_3_18_9_W_CL.tgz 
    echo "... installing clac overlay to /boot/"
    cp -v boot/overlays/rpi-cirrus-wm5102-overlay.dtb /boot/overlays/
    echo "... installing use_case scripts to /home/amon/clac..."
    cp -prv  home/pi/use_case_scripts /home/amon/clac/
    chmod +x /home/amon/clac/*.sh
    
    popd # done fiddling with the debs and tarfile.  Could delete them here (TODO: PURGE)
    echo "... Done installing debs, dtoverlay and control-scripts"

    # now need to change /boot/config.txt to contain:
    # kernel=vmlinuz-3.18.9cludlmmapfll
    # kernel=vmlinuz-3.18.9-v7cludlmmapfll 

    # TODO: this handles only the older RPi versions (not version 2).
    # But we have installed the kernel and modules for both orig and
    # v7 architectures, so it's annoying not to be able to auto-boot
    # the correct one in the same way. Perhaps choosing the same name
    # as originals?  Anyway - I don't know how that intelligence
    # works, so leaving it supporting only orig (not v7/rpi2) boards.

    echo "... Updating /boot/config.txt"
    cp /boot/config.txt /boot/config.txt.pre-provision
    echo "" >> /boot/config.txt # add a new line
    echo "# Below added by solo's provision.sh" >> /boot/config.txt
    echo "kernel=vmlinuz-3.18.9cludlmmapfll" >> /boot/config.txt
    # echo "kernel=vmlinuz-3.18.9-v7cludlmmapfll" >> /boot/config.txt
    echo "dtparam=spi=on" >> /boot/config.txt
    echo "dtoverlay=rpi-cirrus-wm5102-overlay" >> /boot/config.txt
    echo "... done updating /boot/config.txt"

    # now add stuff to blacklist
    echo "... updating blacklist with dependencies"
    bl=/etc/modprobe.d/raspi-blacklist.conf
    echo "... updating $bl"
    #cp $bl $bl.pre-provision # no old version to backup.
    echo "# lines below added by solo's provision.sh" >> $bl
    echo "softdep arizona-spi pre: arizona-ldo1" >> $bl
    echo "softdep spi-bcm2708 pre: fixed" >> $bl
    echo "... done updating blacklist with dependencies"

    # now get the overlay.
    # (crikey, this is a chore...)
    #echo "Getting the device tree overlay."
    #mkdir /opt/solo/cirrus-git
    #pushd /opt/solo/cirrus-git
    #git clone --depth 1 https://github.com/CirrusLogic/rpi-linux.git
    #cp rpi-linux/arch/arm/boot/dts/rpi-cirrus-wm5102-overlay.dtb /boot/overlays/
    # could remove all the kernel sources here TODO PURGE
    #popd 
    #echo "Done getting dtoverlay from Cirrus repo."

    # now get the scripts:
    #echo "...Installing control scripts"
    #mkdir /opt/solo/clacconf/
    #mkdir /opt/solo/clacconf/
    #pushd /opt/solo/clacconf/
    #git clone --depth 1 https://github.com/CirrusLogic/wiki-content.git
    #mv wiki-content/scripts /opt/solo/clacconf
    #chmod +x /opt/solo/clacconf/scripts/*.sh
    #popd
    #echo "...Finished with control scripts"

    echo "Done Installing CLAC stuff..."
fi


if [ $QPURGE = "yes" ] ; then 
    echo "About to purge if required:"

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
else
    echo "Not purging"
fi

DEBUG=yes
if [ $DEBUG ] ; then
    echo "Generating some debug files..."
    debug_dir=/opt/solo/debug/
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
fi

# do this last cos we unmount /boot 
echo
echo "Labeling file system partitions nicely..."
# fatlabel /dev/mmcblk0p1 soloboot
sync
umount /boot 
dosfslabel /dev/mmcblk0p1 soloboot
e2label /dev/mmcblk0p2 solo-sys
sync
echo "Done Labeling file system partitions nicely..."
echo

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
