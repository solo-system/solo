#!/bin/bash

echo "-----------------------"
echo "Welcome to solo-boot.sh"
echo "-----------------------"
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
  echo "No partition p3 on mmc: assuming first boot"
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
  mkdir -p /mnt/sdcard
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
/opt/solo/switchoff.py &
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



# this didn't work and caused a reboot at 22:59:01 every evening (eh?)
#echo "Now adding roots crontab with midnight reboot"
#echo "59 23 * * * /sbin/reboot" | crontab -
#echo "Done with crontabs."

echo
echo "Exiting happy from solo-boot.sh at `date`"
echo 

exit 0
