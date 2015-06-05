#!/bin/bash

echo "=========================================================="
echo "-----------------------"
echo "Welcome to solo-boot.sh"
echo "-----------------------"
echo
echo "Started at: `date` [estimated date/time - RTC not read yet]"

# on raspi model A get: 0008 from /proc/cpuinfo
# on raspi model A+ get: 0012 (also get Hardware = BCM2708
# see: http://elinux.org/RPi_HardwareHistory#Board_Revision_History
# for a full list.

# 2 3 4 5 6 are modelB with 256M Ram
# 7 8 9     are model A with 256Mb
# d e f     are B's with 512 Meg Ram
# 10        Model B+ with 512M ram
# 11        compute module (not supported here)
# 12        A+ with 256M Ram.
# a21041    rev2 model B (newer cpu) with 1G RAM
# ^^^^^^^  I don't trust this from e-linux.org ... TODO: check.

REV=`grep Revision /proc/cpuinfo  | awk '{print $3}'`
if [ "$REV" = 0002 ] ; then
    IICBUS=0
else
    IICBUS=1
fi

### NEW!!! properly understand the revision of the board:

case $REV in

    0002 | 0003 | 0004 | 0005 | 0006)
        echo "rev is $REV: hardware is version 2,3,4,5,6 - model B with 256M RAM"
        RPINAME="B"
	RPIMEM="256"
        ;;

    0007 | 0008 | 0009)
        echo "rev is $REV: hardware is version 7,8,9 = model A with 256M RAM"
	RPINAME="A"
	RPIMEM="256"
        ;;

    000d | 000e | 000f)
        echo "rev is $REV: hardware is version d,e,f = model B with 512M RAM"
	RPINAME="B"
	RPIMEM="512"
        ;;

    0010)
        echo "rev is $REV: hardware is version 10 = model B+ with 512M RAM"
	RPINAME="B+"
	RPIMEM="512"
        ;;

    0011)
        echo "rev is $REV: hardware is version 11 = compute module (Not Supported - I wonder what will happen)"
	RPINAME="CM"
	RPIMEM="512"
        ;;

    0012)
        echo "rev is $REV: hardware is version 12 = model A+ with 256M RAM"
	RPINAME="A+"
	RPIMEM="256"
        ;;
    *)
	echo "rev is $REV: hardware version recognised."
esac

KRNL=$(uname -r | cut -f1,2 -d'.')
FULL_KERNEL=$(uname -r)

# do we have a CLAC installed?
if grep sndrpiwsp /proc/asound/cards > /dev/null ; then 
    CLAC=yes
else
    CLAC=no
fi

echo "... Finished detecting raspberry pi hardware: RPINAME=$RPINAME, RPIMEM=$RPIMEM"
echo "... Detected KRNL version $KRNL ($FULL_KERNEL)"
echo "... Detected raspi hardware version $REV so using i2c bus $IICBUS"
echo "... Is Cirrus Logic Audio Card installed?  CLAC=$CLAC"
echo
echo

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
  fcmd="n\np\n3\n$startnew\n\nw"
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

  SOLOLOGDIR=/mnt/sdcard/solo-logs
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

echo
echo "=================================================="
echo "Disabling tvservice to save power"
/opt/vc/bin/tvservice -off
echo "Done Disabling tvservice to save power"
echo "=================================================="
echo

# only start switchoff if this is NOT a wolfson/cirrus install
# since don't know how to do GPIO with wolfson/cirrus.
echo
echo "=================================================="
echo "Starting the switchoff.py monitor script"
if [ $CLAC = "no" ] ; then
    echo "... starting switchoff.py"
    /opt/solo/switchoff.py &
else
    echo "... NOT starting switchoff.py, cos it's a cirrus install and I don't know the pins"
fi
echo "Done - Starting the switchoff monitor script"
echo "=================================================="
echo

### LEDs - set them up.
# on RJ's img we have two leds (/sys/class/leds/led{0,1}.
# led0    GREEN    (originally "activity")
# led1    RED      (originally power)
# We how have control of the RED one (which
# is good).. TODO - should do something clever with these two.  NOTE
# BOTH of these are on the rpi board NOT the CLAC.  Don't know how to
# control the CLAC leds.
# On the rpi version B - we had either led0 or (with newer kernels) ACT.
# It seems with Ragnar Jensens' image, and a CLAC on rpi
# version B+, the ACT is no longer, and it's back to led0 and led1.

echo
echo "=================================================="
echo "Activating the LEDs [`date`]"

if [ $RPINAME = "B+" -o $RPINAME = "A+" ] ; then
    echo heartbeat > /sys/class/leds/led0 # heartbeat on green LED
    echo none      > /sys/class/leds/led1 # turn off the red LED
else
    echo "don't know how to set LEDs on this hardware: $RPINAME"
    ls -l /sys/class/leds/
    echo "please update solo-boot.sh"
fi    

#for ledpath in /sys/class/leds/ACT/trigger /sys/class/leds/led0/trigger ; do
#    if [ -f $ledpath ] ; then
#	echo "... Enabling led=$ledpath to be a heartbeat."
#	echo heartbeat > $ledpath
#	led_done=$((led_done+1))
#    fi
#done

echo "Done - Activating the LEDs [`date`]"
echo "=================================================="
echo

# now set up the RTC clock (should we not do this WAY before now?)
echo
echo "=================================================="
echo "Activating the RTC clock at [`date`]"
modprobe i2c-dev
echo "... inserted module i2c-dev (so i2c bus appears in /dev)"
REGPATH=/sys/class/i2c-adapter/i2c-${IICBUS}/new_device # where to register new devices

echo "... we don't know which clock is attached, so add all (both) types"
echo "... adding lshaped clock"
echo "... informing kernel of rtc (DS-1307 L-shaped) device"
echo ds1307 0x68 > /sys/class/i2c-adapter/i2c-${IICBUS}/new_device
echo "... Done adding lshaped clock"
echo "... Adding second clock - piface shim"
modprobe i2c:mcp7941x # why don't we need a modprobe for the l-shaped?
echo "... loaded mcp7941x module"
echo "... informing kernel of rtc (piface shim) device"
echo mcp7941x 0x6f > /sys/class/i2c-dev/i2c-${IICBUS}/device/new_device
echo "... Done adding piface-shim clock"
echo "... Did it work?"

sleep 2 # let the above setup settle. TODO: get rid of this ??? if DT handled it, kernel loaded RTC ages ago.

if [ -e /dev/rtc0 ] ; then 
    echo "... I see a clock - good."
else
    echo "... WARNING - I see NO clock"
fi

echo "Done ... Activating the RTC clock(s) at [`date`]"
echo "=================================================="
echo

# now interrogate the clock and set system time from it.  Should really use test-rtc.sh for this???
echo
echo "=================================================="
echo "Setting the time... [`date`]"

echo "... Reading rtc..."
rtctime=`/sbin/hwclock -r`  # read time on rtc 
rtctime=`/sbin/hwclock -r`  # read time a second time, incase first fails.
echo "... RTC reports time is $rtctime"

if [ "$rtctime" ] ; then # this test should check that rtctime is > 2015-01-01
    echo "... setting system time from rtc at `date`"
    /sbin/hwclock -s  # set system time from it
    echo "... ZOOM into the future..." 
    echo "... system time is now: `date`"
else
    echo "NOT setting system time, cos rtc didn't give a good answer"
fi

echo "Done ... Setting the time at  [`date`]"
echo "=================================================="
echo

if [ $DEBUG = "on" ] ; then
    echo "DEBUG mode is on - so doing lots of lsusb stuff"
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
