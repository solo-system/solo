#!/bin/bash

# Mount partition in a disk image as it's own loop device

img=images/systemImage-2014-10-14.img
img=images/2014-09-09-wheezy-raspbian.img
img=images/solo-2015-01-16.img
img=test.img

if [ ! -f $img ] ; then 
    echo "Error - no such image $img"
    exit -1
fi

# It's only partition 2 we want (for the moment)
rootoffset=`fdisk -l $img | tail -2 | head -1 | awk '{print $2}';`
#dataoffset=`fdisk -l $img | tail -1 | head -1 | awk '{print $2}';`

#echo "[ignoring boot partition]"
echo root partition starts at: $rootoffset
#echo data partition starts at: $dataoffset

echo "any key to continue or ctrl-c to abort ?????"
read

sudo losetup -v -o $(($rootoffset*512)) /dev/loop0 $img
mkdir -p p1
sudo mount /dev/loop0 p1

echo "mounted partition 1 in directory \"p1\":" 
df p1

# OLD way - using mount with offsets.
# mkdir -p mnt-boot mnt-root
# sudo mount -o loop,offset=$(($bootoffset*512)) $img mnt-boot/
# sudo mount -o loop,offset=$(($rootoffset*512)) $img mnt-root/

echo "REMEMBER TO UMOUNT THEM with:"
echo "sudo umount p1 ; sudo losetup -d /dev/loop0 ; rmdir p1"
echo 

exit 0
