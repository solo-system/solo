#!/bin/bash

function log() {
    msg="$1"
    out="[SHRINK IMAGE]: $msg"
    echo "$out"
}

# takes an img file and reduces the size of it.
img=first.img

if [ ! -f $img ] ; then 
    echo "Error - no such image $img"
    exit -1
fi

# It's only partition 2 we want (for the moment)
rootoffset=`fdisk -l $img | tail -1 | head -1 | awk '{print $2}';`
log "root partition starts at: $rootoffset"

log "setting up loop with offset..."
sudo losetup -v -o $(($rootoffset*512)) /dev/loop0 $img  # build a device.

log "fscking filesystem..."
sudo e2fsck -f /dev/loop0  # do this a lot to keep sane.

log "removing journal..."
sudo tune2fs -O ^has_journal /dev/loop0 #get rid ofjournal prior to resize.

log "fscking again to be paranoid"
sudo e2fsck -f /dev/loop0 # do it again to feel safe. it reports: 236827/784640 blocks

log "resizing to minimum size [TAKES TIME] ..."
sudo resize2fs -M /dev/loop0  # do the resize to the minimum sixe

log "checking fs again..."
sudo e2fsck -f /dev/loop0

log "Finding new size of fs:"
newsize4k=$(sudo dumpe2fs /dev/loop0 | grep "Block count:" | awk '{print $3}')
newsize4kplus=$((newsize4k + 50000)) # add 200Mb free space.
log "new size is $newsize4k (4kb), adding 200Mb (50,000 x 4kb) gives desired size of $newsize4kplus"

log "resizing to desired size of $newsize4kplus ..."
sudo resize2fs /dev/loop0 $newsize4kplus

# BUG: this doesn't buy us 200M in the final product - only 148M: (does the journal need 50Mb perhaps)
# jdmc2@t510j ~/git/solo/p1 $ df -h .
# Filesystem      Size  Used Avail Use% Mounted on
# /dev/loop0      1.1G  877M  148M  86% /home/jdmc2/git/solo/p1
# jdmc2@t510j ~/git/solo/p1 $ df .
# Filesystem     1K-blocks   Used Available Use% Mounted on
# /dev/loop0       1122084 897548    151128  86% /home/jdmc2/git/solo/p1


log "Finding new size of fs:"
newsize4k=$(sudo dumpe2fs /dev/loop0 | grep "Block count:" | awk '{print $3}')
newsize1k=$((newsize4k * 4))
log "New (desired) size of fs is $newsize4k (4k blocks), or $newsize1k (1k blocks)"

log "Rebuilding the journal..."
sudo tune2fs -j /dev/loop0

log "syncing disks..."
sync # paranoia

log  "removing /dev/loop0"
sudo losetup -d /dev/loop0

log "done with all the stuff at fs level - now doing MBR/partition stuff..."
log "Doing the partition table shrink..."
# now we want to resize the partition in the MBR
fcmd="d \n 2 \n n \n p \n 2 \n 122880 \n +${newsize1k}K \n w"
echo -e $fcmd | fdisk $img

log "Done partition table shrink... Table now looks like:"
sudo fdisk -l $img

# when I did this "exactly" I was off by one:
# EXT4-fs (loop0): bad geometry: block count 285148 exceeds size of device (285147 blocks)
# so add one 512k block - and that fixes it - Yay!

log "now done with the MBR/partition table level stuff - now truncate the .img file"
lastpartoffset=`fdisk -l $img | tail -1 | awk '{print $3}';`
truncatesize=$(((lastpartoffset+1)*512))
log "truncating to $lastpartoffset * 512 bytes = $truncatesize"
truncate -s $truncatesize $img

log "truncate done - ls -l $img:"
ls -l $img

log "now zipping..."
log "not really - not yet"
#zip $img.zip $img

echo "-------------------------------------------------------"
echo "examine new ext2 contents with:"
echo "sudo mount -o loop,offset=\$((122880*512)) $img p1"
echo "Or check for stray dev/loops with losetup -a"
echo "Exiting happy."

exit 0

# Using : dumpe2fs /dev/loop0 gives:
# Block count:              234122
# Block size:               4096
# The top number matches the size given out by the resize2fs tool. Yay
# - we don't need to sweep for it.
