#!/bin/bash

# takes an img file and reduces the size of it.
img=solo-2015-02-10.img

if [ ! -f $img ] ; then 
    echo "Error - no such image $img"
    exit -1
fi

# It's only partition 2 we want (for the moment)
rootoffset=`fdisk -l $img | tail -1 | head -1 | awk '{print $2}';`
echo root partition starts at: $rootoffset

echo "SOLO: setting up loop with offset..."
sudo losetup -v -o $(($rootoffset*512)) /dev/loop0 $img

echo "SOLO: fscking filesystem..."
sudo e2fsck -f /dev/loop0

echo "SOLO: removing journal..."
sudo tune2fs -O ^has_journal /dev/loop0 #get rid ofjournal prior to 

echo "SOLO: fscking again to be paranoid"
sudo e2fsck -f /dev/loop0 # do it again to feel safe. it reports: 236827/784640 blocks

echo "resizing to minimum size ..."
sudo resize2fs -M /dev/loop0

echo "fs checking.."
sudo e2fsck -f /dev/loop0

echo "Finding new size of fs:"
newsize4k=$(sudo dumpe2fs /dev/loop0 | grep "Block count:" | awk '{print $3}')
newsize1k=$((newsize4k * 4))
echo "New size of fs is $newsize4k (4k blocks), or $newsize1k (1k blocks)"

echo "removing /dev/loop0"
sudo losetup -d /dev/loop0

echo "Doing the partition table shrink..."
# now we want to resize the partition in the MBR
fcmd="d \n 2 \n n \n p \n 2 \n 122880 \n +${newsize1k}K \n w"
echo -e $fcmd | fdisk $img

echo "Done partition table shrink..."
echo "Table now looks like:"
sudo fdisk -l $img

echo "now doing the truncate, to make the img file smaller"
lastpartoffset=`fdisk -l $img | tail -1 | awk '{print $3}';`
truncate -s $((lastpartoffset*512)) $img
echo "truncate done - ls -l $img:"
ls -l $img
echo "now zipping..."
#not yet
#zip $img.zip $img



echo
echo
echo
echo
echo
echo "you can look into the newly sized linux partition with:"
echo "CMD: sudo mount -o loop,offset=\$((122880*512)) test.img p1"
echo "- check for stray dev/loops with losetup -a"
echo "Exiting happy - new image is in $img"

exit 0

# dumpe2fs /dev/loop0 gives:
# Block count:              234122
# Block size:               4096

# The top number matches the size given out by the resize2fs tool. Yay - we don't need to sweep for it.

