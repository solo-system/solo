#!/bin/bash

# TODO: should be cleverer in reading hwclock. If < 2014, don't set sys time.
#       also - if `date` is already >=2014, then must be networked - so SET rtc from sys ?

echo "------------------------"
echo "Welcome to normalboot.sh"
echo "------------------------"
echo

echo "Started at: `date`"

# just got 2 raspi A's that report rev as 0008!
REV=`grep Revision /proc/cpuinfo  | awk '{print $3}'`
if [ "$REV" = 0002 ] ; then
    IICBUS=0
else
    IICBUS=1
fi
echo "detected raspi hardware version $REV"

# if p3 doesn't exist, make it, mount it.
if ! grep mmcblk0p3 /proc/partitions > /dev/null ; then
  echo "First-boot: making new partition at `date`"
  echo "... Making partition p3 on /dev/mmcblk0 ..."

  echo "finding last partition of p2..."
  endlast=`fdisk -l /dev/mmcblk0 | grep /dev/mmcblk0p2 | awk '{print $3}'`
  startnew=$((endlast+1))
  fcmd="n\np\n3\n$startnew\n\nw"
  echo -e $fcmd | fdisk /dev/mmcblk0 > /opt/recorder/fdisk.log
  echo "... running partprobe..."
  partprobe
  echo "... running mkfs.vfat"
  mkfs.vfat -v -n AUDIO /dev/mmcblk0p3 > /opt/recorder/mkfs.vfat.log
  fstabtxt="/dev/mmcblk0p3  /mnt/sdcard     vfat    defaults,noatime,umask=111,dmask=000  0  2"
  echo $fstabtxt >> /etc/fstab
  mkdir -p /mnt/sdcard
  echo "... remounting.."
  mount -a
  mkdir /mnt/sdcard/amondata
  # chown amon.amon /mnt/sdcard/amondata
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

### do normal setup required for deployed recorders
echo 
echo "starting: switchoff, tvservice, and heartbeat at `date`"
/opt/recorder/switchoff.py &
/opt/vc/bin/tvservice -off
echo heartbeat > /sys/class/leds/led0/trigger
# amixer -q -c 1 set "Mic" 15dB
echo "Done starting switchoff, tvservice, and heartbeat at `date`"
echo

echo "Setting up the clock at `date`"
echo "... detected raspi revision $REV"
echo ds1307 0x68 > /sys/class/i2c-adapter/i2c-${IICBUS}/new_device
echo "... informed the kernel of new_device at `date`"
sleep 1 # let is settle.
ls -l /dev/rtc0
/sbin/hwclock -r  # read it 
echo "... setting system time from rtc at `date`"
/sbin/hwclock -s  # set system time from it
echo "ZOOM into the future..." 
echo "Done setting up the clock. New time is : `date`"
echo


# add crontabs ...
echo
echo "Now adding watchdog to amon's crontab:"
echo "* * * * * /home/amon/amon/amon watchdog >> /home/amon/amon/cron.log 2>&1" | crontab -u amon -

# this didn't work and caused a reboot at 22:59:01 every evening (eh?)
#echo "Now adding roots crontab with midnight reboot"
#echo "59 23 * * * /sbin/reboot" | crontab -
#echo "Done with crontabs."

echo
echo "Exiting happy from normalboot.sh at `date`"
echo 

exit 0
