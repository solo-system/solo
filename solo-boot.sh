#!/bin/bash

echo "-----------------------"
echo "Welcome to solo-boot.sh"
echo "-----------------------"
echo
echo "Started at: `date`"

# on raspi model A get: 0008 from /proc/cpuinfo
REV=`grep Revision /proc/cpuinfo  | awk '{print $3}'`
if [ "$REV" = 0002 ] ; then
    IICBUS=0
else
    IICBUS=1
fi

KRNL=$(uname -r | cut -f1,2 -d'.')
if [ $KRNL = "3.12" ] ; then
    DT=no
elif [ $KRNL = "3.18" ] ; then
    DT=yes
else
    DT=unknown
fi

echo "Detected KRNL version $KRNL, so assuming device tree is $DT"
echo "detected raspi hardware version $REV so using i2c bus $IICBUS"

### TODO - this doesn't catch the situation where the partition is
### made, but the fs isn't (or the FS is corrupt).  Instead, we should
### check for the presence of the FS. somehow.  I just saw this on a
### PI which had a power fail during initial boot (presumably AFTER
### fdisk made the partition, but before the FS was written (and added
### to fstab).  Perhaps we should check here for the existence of p3
### in /etc/fstab (the last bit of the below).  We should also "sync"
### after making the fs and sync after changing fstab.  The fstab on
### the pi in question was corrupt with lots of ^0^0^0 in it.
## I've added 2 lines below tagged TRYTHIS:

# if p3 doesn't exist, make it, mount it.
#if ! grep mmcblk0p3 /proc/partitions > /dev/null ; then
if ! grep mmcblk0p3 /proc/mounts > /dev/null ; then
  echo "No mount associated with p3 on mmc: assuming first boot - building..."
  # TODO: should refactor first boot() into a function
  echo "First-boot: making new partition at `date`"
  echo "... Making partition p3 on /dev/mmcblk0 ..."

  echo "finding last partition of p2..."
  endlast=`fdisk -l /dev/mmcblk0 | grep /dev/mmcblk0p2 | awk '{print $3}'`
  startnew=$((endlast+1))
  fcmd="n\np\n3\n$startnew\n\nw"
  echo "running $fcmd > fdisk"
  echo -e $fcmd | fdisk /dev/mmcblk0 > /opt/solo/fdisk.log
  echo "... running partprobe..."
  partprobe
  echo "... running mkfs.vfat"
  mkfs.vfat -v -n AUDIO /dev/mmcblk0p3 > /opt/solo/mkfs.vfat.log
  fstabtxt="/dev/mmcblk0p3  /mnt/sdcard     vfat    defaults,noatime,umask=111,dmask=000  0  2"
  echo $fstabtxt >> /etc/fstab

  ### TRYTHIS - add a sync to ensure the mkfs and fstab work sticks.
  echo "syncing disks..."
  sync

  mkdir -p /mnt/sdcard

  ### TRYTHIS - add a second sync to ensure the mkdir sticks - whynot ???
  sync

  echo "... remounting.."
  mount -a
  mkdir /mnt/sdcard/amondata
  # chown amon.amon /mnt/sdcard/amondata
  # now build the crontab:
  # add crontabs ... (these should NOT be here - since they overwrite with each boot).
  echo
  echo "Now adding watchdog and playback to amon's crontab:"
  echo -e "* * * * * /home/amon/amon/amon watchdog >> /home/amon/amon/cron.log 2>&1\n#0 */2 * * * /home/amon/amon/playback.sh >> /home/amon/amon/playback.log 2>&1" | crontab -u amon -
  echo "Done building crontab"

  echo "First-boot: finished at `date`"
else 
  echo "NOTE: p3 is already there - great, lets get on with it."
fi

###
echo "Checking disk free info:"
df -h
echo "--------------"
mount
echo "Done checking disk free info."

### do normal setup required for deployed solos
echo 
echo "starting: switchoff, tvservice, and heartbeat at `date`"
/opt/vc/bin/tvservice -off

# only start switchoff if this is NOT a wolfson/cirrus install
# since don't know how to do GPIO with wolfson/cirrus.
if [ $DT = "yes" ] ; then
    echo "starting switchoff.py"
    /opt/solo/switchoff.py &
else
    echo "NOT starting switchoff.py, cos it's a cirrus install"
fi

if [ $DT = "yes" ] ; then
    LED=/sys/class/leds/ACT/trigger
else
    LED=/sys/class/leds/led0/trigger
fi

if [ ! -f $LED ] ; then 
  echo "WARNING: no LED detected - programmer error"
fi

echo "starting heartbeat in $LED"
[ -f $LED ] && echo heartbeat > $LED
echo "Done starting heartbeat in $LED"

echo "Done starting switchoff, tvservice, and heartbeat at `date`"
echo

echo "Setting up the clock at `date`"
echo "... detected raspi revision $REV"

if [ $DT = no ] ; then
    echo "doing modprobe i2c-dev"
    modprobe i2c-dev
    RTC=/sys/class/i2c-adapter/i2c-${IICBUS}/new_device
    if [ -f $RTC ] ; then
	echo "informing kernel of rtc (DS-1307 L-shaped) device"
	echo ds1307 0x68 > /sys/class/i2c-adapter/i2c-${IICBUS}/new_device
	echo "informing kernel of rtc (MCP-7941x piface shim) device"
	echo mcp7941x 0x6f > /sys/class/i2c-adapter/i2c-${IICBUS}/new_device
	echo "done informing kernel of rtc device"
    else
	echo "Warning: Can't find RTC device in $RTC"
    fi
else
    echo "HELP - do we need to do anything here.  Device Tree should handle it all I think"
fi

echo "Done setting up clock at `date`"
sleep 1 # let is settle.
ls -l /dev/rtc0
/sbin/hwclock -r  # read it 
echo "... setting system time from rtc at `date`"
/sbin/hwclock -s  # set system time from it
echo "ZOOM into the future..." 
echo "Done setting up the clock. New time is : `date`"
echo

echo
echo "Exiting happy from solo-boot.sh at `date`"
echo 

exit 0
