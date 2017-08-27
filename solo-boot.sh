#!/bin/bash

# What happens if we do (TODO)
# set -x

echo "=========================================================="
echo "-----------------------"
echo "Welcome to solo-boot.sh"
echo "-----------------------"
echo
echo "[solo-boot.sh] Started at: `date`"


if [ ! -r /opt/solo/utils.sh ] ; then
    echo "Error: can't read /opt/solo/utils.sh - this is probably bad news!"
fi
source /opt/solo/utils.sh

# find out which hardware platform we are on:

REV=$(grep Revision /proc/cpuinfo  | awk '{print $3}')


KRNL=$(uname -r | cut -f1,2 -d'.')
FULL_KERNEL=$(uname -r)

# do we have a CLAC installed?
if grep RPiCirrus /proc/asound/cards > /dev/null ; then
    CLAC=yes
else
    CLAC=no
fi

echo "... Finished detecting raspberry pi hardware: REV=$REV RPINAME=$RPINAME"
echo "... Detected KRNL version $KRNL ($FULL_KERNEL)"
echo "... Is Cirrus Logic Audio Card installed?  CLAC=$CLAC"
echo
echo

# a place to copy logs on the p3 partition
#SOLOLOGDIR=/mnt/sdcard/solo-logs

# read the user-supplied config file, if it exists
if [ -f /boot/solo/solo.conf ] ; then
    source /boot/solo/solo.conf
fi

### TODO - this doesn't catch the situation where the partition is
### made, but the fs isn't (or the FS is corrupt).  Instead, we should
### check for the presence of the FS. somehow.  I just saw this on a
### PI which had a power fail during initial boot (presumably AFTER
### fdisk made the partition, but before the FS was written (and added
### to fstab).  Perhaps we should check here for the existence of p3
### in /etc/fstab (the last bit of the below).  We should also "sync"
### after making the fs and sync after changing fstab.  The fstab on
### the pi in question was corrupt with lots of ^0^0^0 in it.

# if p3 doesn't exist, make it, mount it.
#if ! grep mmcblk0p3 /proc/partitions > /dev/null ; then
if ! grep mmcblk0p3 /proc/mounts > /dev/null ; then
  echo "==============================="
  echo "FIRSTBOOT: No mount associated with p3 on mmc: assuming first boot - building..."
  # TODO: should refactor first boot() into a function
  echo "... First-boot: making new partition at `date`"
  echo "... Making partition p3 on /dev/mmcblk0 ..."
  echo "... finding last partition of p2..."
  endlast=`fdisk -l /dev/mmcblk0 | grep /dev/mmcblk0p2 | awk '{print $3}'`
  startnew=$((endlast+1))
  echo "... endlast = $endlast and startnew=$startnew".
  #fcmd="n\np\n3\n$startnew\n\nw"
  fcmd="n\np\n3\n$startnew\n\nt\n3\nc\nw" # set type of p3 to FAT (c)
  echo "... running $fcmd > fdisk"
  echo -e $fcmd | fdisk /dev/mmcblk0 > /opt/solo/fdisk.log
  echo "... running partprobe..."
  partprobe
  echo "... running mkfs.vfat"
  mkfs.vfat -v -n solo-data /dev/mmcblk0p3 > /opt/solo/mkfs.vfat.log
  fstabtxt="/dev/mmcblk0p3  /mnt/sdcard     vfat    defaults,noatime,umask=111,dmask=000  0  2"
  echo $fstabtxt >> /etc/fstab

  ### add a sync to ensure the mkfs and fstab work sticks.
  echo "... syncing disks..."
  sync

  echo "... Making /mnt/sdcard mount point"
  mkdir -p /mnt/sdcard

  echo "... syncing again (paranoid)"
  sync

  echo "... remounting to get new mount of p3"
  mount -a

  echo "... making directory amondata on new mount point"
  mkdir /mnt/sdcard/amondata

#  echo "... making directory $SOLOLOGDIR on new mount point"
#  mkdir $SOLOLOGDIR

  # chown amon.amon /mnt/sdcard/amondata
  # now build the crontab:
  # add crontabs ... (these should NOT be here - since they overwrite with each boot).

#  echo "... placing output of df and mount into logs for inspection"
#  df -h > $SOLOLOGDIR/df.txt
#  mount > $SOLOLOGDIR/mount.txt

  # set up the watchdog to run every minute:
  echo "Adding amon watchdog to crontab every minute"
  echo -e "* * * * * /home/amon/amon/amon watchdog >> /mnt/sdcard/amondata/logs/cron.log 2>&1\n" | crontab -u amon -

  echo "FIRSTBOOT: finished at `date`"
  echo "======================================================"
else
  echo "FIRSTBOOT: p3 is already there - great. Not activating FIRSTBOOT code."
fi



# forget this, nobody uses the  off-switch.
# only start switchoff if this is NOT a wolfson/cirrus install
# since don't know how to do GPIO with wolfson/cirrus.
#echo
#echo "=================================================="
#echo "Starting the switchoff.py monitor script"
#if [ $CLAC = "no" ] ; then
#    echo "... starting switchoff.py"
#    /opt/solo/switchoff.py &
#else
#    echo "... NOT starting switchoff.py, cos it's a cirrus install and I don't know the pins"
#fi
#echo "Done - Starting the switchoff monitor script"
#echo "=================================================="
#echo

setup_rtc_udev # setup of the RTC - using udev and systemd
minimize_power # ensure low power (tvservice off)
setup_leds     # set up the leds
set_timezone   # set timezone to SOLO_TZ (from solo.conf)


#if [ $DEBUG = "on" ] ; then
#    echo "DEBUG mode is on - so doing lots of lsusb stuff"
    # echo "DEBUG mode is on in solo-boot.sh so copying files to here.  It's just at the end of boot-time when these copies are made" > $SOLOLOGDIR/README.txt

#    echo "lsusb ..."
#    lsusb > $SOLOLOGDIR/lsusb.txt
#    echo "lsusb -t"
#    lsusb -t > $SOLOLOGDIR/lsusb-t.txt
#    echo "lsusb -v"
#    lsusb -v > $SOLOLOGDIR/lsusb-v.txt
#    echo "dmesg"
#    dmesg > $SOLOLOGDIR/dmesg.txt.postboot

    # TODO: there are more things in /var/log which we could copy:
    # The problem is that we are just at boot time, and so we end
    # up with only partial copies.
#    echo "end of debug mode"

#fi

#echo "about to exit - copying this log output to $SOLOLOGDIR..."
#cp /opt/solo/solo-boot.log $SOLOLOGDIR/solo-boot.log
echo
echo "that's all folks"
echo
echo "Exiting happy from solo-boot.sh at `date`"
echo

exit 0
