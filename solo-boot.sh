#!/bin/bash

echo "=========================================================="
echo "-----------------------"
echo "Welcome to solo-boot.sh"
echo "-----------------------"
echo
echo "[solo-boot.sh] Started at: `date`"

# what am I ?
# This helps: http://www.raspberrypi-spy.co.uk/2012/09/checking-your-raspberry-pi-board-version/
REV=`grep Revision /proc/cpuinfo  | awk '{print $3}'`

if [ ! -r /opt/solo/utils.sh ] ; then
    echo "Error: can't read /opt/solo/utils.sh - this is probably bad news!"
fi
source /opt/solo/utils.sh

# find out which hardware platform we are on:
case $REV in

    0002 | 0003 | 0004 | 0005 | 0006)
        echo "... rev is $REV: hardware is version 2,3,4,5,6 - model B with 256M RAM"
        RPINAME="B"
	RPIMEM="256"
	IICBUS=0
        ;;

    0007 | 0008 | 0009)
        echo "... rev is $REV: hardware is version 7,8,9 = model A with 256M RAM"
	RPINAME="A"
	RPIMEM="256"
	IICBUS=1
	;;

    000d | 000e | 000f)
        echo "... rev is $REV: hardware is version d,e,f = model B with 512M RAM"
	RPINAME="B"
	RPIMEM="512"
	IICBUS=1
        ;;

    0010)
        echo "... rev is $REV: hardware is version 10 = model B+ with 512M RAM"
	RPINAME="B+"
	RPIMEM="512"
	IICBUS=1
        ;;

    0011)
        echo "... rev is $REV: hardware is version 11 = compute module"
	echo "... Hardware Not Supported - I wonder what will happen."
	RPINAME="CM"
	RPIMEM="512"
	IICBUS=1
        ;;

    0012 | 0015)
        echo "... rev is $REV: hardware is version 12 = model A+ with 256M RAM"
	RPINAME="A+"
	RPIMEM="256"
	IICBUS=1
	;;

    a01041 | a21041)
	echo "... rev is $REV: hardware is pi2 B with 1G RAM"
	RPINAME="PI2B"
	RPIMEM="1024"
	IICBUS=1
	;;

    a02082)
	echo "... rev is $REV: hardware is pi3 B with 1G RAM"
	RPINAME="PI3B"
	RPIMEM="1024"
	IICBUS=1
	;;

    *)
	echo "... rev is $REV: hardware NOT RECOGNISED (please update solo-boot.sh)"
	echo "... ASSUMING hardware is pi2"
	RPINAME="PI2B"
	RPIMEM="1024"
	IICBUS=1
	;;
esac

KRNL=$(uname -r | cut -f1,2 -d'.')
FULL_KERNEL=$(uname -r)

# do we have a CLAC installed?
if grep sndrpiwsp /proc/asound/cards > /dev/null ; then
    CLAC=yes
else
    CLAC=no
fi

echo "... Finished detecting raspberry pi hardware: RPINAME=$RPINAME, RPIMEM=$RPIMEM IICBUS=$IICBUS"
echo "... Detected KRNL version $KRNL ($FULL_KERNEL)"
echo "... Is Cirrus Logic Audio Card installed?  CLAC=$CLAC"
echo
echo

# a place to copy logs on the p3 partition
SOLOLOGDIR=/mnt/sdcard/solo-logs

# read the user-supplied config file, if it exists
if [ -f /boot/solo.conf ] ; then
    source /boot/solo.conf
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

  echo "... making directory $SOLOLOGDIR on new mount point"
  mkdir $SOLOLOGDIR

  # chown amon.amon /mnt/sdcard/amondata
  # now build the crontab:
  # add crontabs ... (these should NOT be here - since they overwrite with each boot).

  echo "... placing output of df and mount into logs for inspection"
  df -h > $SOLOLOGDIR/df.txt
  mount > $SOLOLOGDIR/mount.txt

  echo "... Finished doing new partition stuff, now other chores for FIRSTBOOT:"
  echo "... adding watchdog and playback to amon's crontab:"
  echo -e "* * * * * /home/amon/amon/amon watchdog >> /home/amon/amon/cron.log 2>&1\n#0 */2 * * * /home/amon/amon/playback.sh >> /home/amon/amon/playback.log 2>&1" | crontab -u amon -
  echo "... Done building crontab"

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

minimize_power # ensure low power (tvservice off)
setup_leds     # set up the leds
set_timezone   # set timezone to SOLO_TZ (from solo.conf)


if [ $DEBUG = "on" ] ; then
    echo "DEBUG mode is on - so doing lots of lsusb stuff"
    # echo "DEBUG mode is on in solo-boot.sh so copying files to here.  It's just at the end of boot-time when these copies are made" > $SOLOLOGDIR/README.txt

    echo "lsusb ..."
    lsusb > $SOLOLOGDIR/lsusb.txt
    echo "lsusb -t"
    lsusb -t > $SOLOLOGDIR/lsusb-t.txt
    echo "lsusb -v"
    lsusb -v > $SOLOLOGDIR/lsusb-v.txt
    echo "dmesg"
    dmesg > $SOLOLOGDIR/dmesg.txt.postboot

    # TODO: there are more things in /var/log which we could copy:
    # The problem is that we are just at boot time, and so we end
    # up with only partial copies.
    echo "end of debug mode"

fi

echo "about to exit - copying this log output to $SOLOLOGDIR..."
cp /opt/solo/solo-boot.log $SOLOLOGDIR/solo-boot.log
echo
echo "that's all folks"
echo
echo "Exiting happy from solo-boot.sh at `date`"
echo

exit 0
