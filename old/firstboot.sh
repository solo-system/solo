#!/bin/bash

DONE=/root/firstboot.DONE
FLAGFILE=/root/run-firstboot

if [ -f $DONE ] ; then 
    echo "/root/firstboot.sh: DONE file \"$DONE\" exists - I have nothing to do here"
    exit 0
fi

# note - we can't make a new partition and then re-read
# the partition table because the kernel refuses to
# (since table contains active partition p2 (slash)
# so need to do this in 2 bits.
# this may change if we could initially mount / read only

echo
echo "-------------------------------"
echo "firstboot running at `date`"
echo "-------------------------------"
echo
echo "getting partition table..."
fdisk -l > /root/partition.table

if ! grep /dev/mmcblk0p3 /root/partition.table > /dev/null ; then
    echo "Making p3 - since partition table has no p3"
    echo "making p3 and calling reboot..."
    last=`fdisk -l | tail -1  |  awk '{print $3}'`
    lastplus=$(($last +1))    
    cmd="p\n n\n p\n 3\n ${lastplus}\n \n p\n w\n" #extra \n gives max size
    echo "fdisk tells me p2 finishes at $last, so building new p3 at $lastplus"
    echo -e $cmd  | fdisk /dev/mmcblk0 > /root/fdisk.log
    echo "done with fdisk. Here is the new partition table:"
    fdisk -l /dev/mmcblk0
    echo "-------------------------"
    echo "calling reboot (since kernel won't re-read due to mounted slash)"
    reboot
    exit 0
fi

echo "ensuring we never run firstboot again"
touch $DONE # So we NEVER run this script again.
# rm /root/FIRSTBOOT # it should really be this...
echo
echo "p3 already exists, so make the filesystem, add to fstab, and mount"

# mkfs.ext4 /dev/mmcblk0p3
mkfs.vfat -v -n AUDIODATA /dev/mmcblk0p3

echo "adding it to fstab..."
#fstabtxt="/dev/mmcblk0p3  /mnt/sdcard     ext4    defaults,noatime  0  2"
fstabtxt="/dev/mmcblk0p3  /mnt/sdcard     vfat    defaults,noatime,umask=111,dmask=000  0  2"
echo $fstabtxt >> /etc/fstab


# make the mount point
echo "making the mount point..."
mkdir -p /mnt/sdcard
echo "remounting"
mount -a
echo "here is output of mount"
mount
echo "making amondata dir with approprate ownership..."
mkdir /mnt/sdcard/amondata
# chown amon.amon /mnt/sdcard/amondata not for vfat thanks

echo "Now adding watchdog to amon's crontab:"
echo "* * * * *       /home/amon/amon/amon watchdog >> /home/amon/amon/cron.log 2>&1" | crontab -u amon -

echo "need to add nightly reboot to root's crontab"
echo "59 23 * * * /sbin/reboot" | crontab -
echo "Done with crontabs."

echo "firstboot phase 2 complete.  System should be ready to use"


# -------------------------------------------
# end of the partition/filesystem stuff
# can put other commands here if you like.  They will be run once at
# the very first boot - (phase 2 of that, after the fdisk has
# rebooted...).

exit 0
