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


### resize stuff is below
originally, df said 2721336 x 1k blocks  AND 707840 (blocks) from e2fsck.
resize says: Resizing the filesystem on /dev/loop0 to 498264 (4k) blocks.
e2fsck now says 498264 4k blocks.  (mount, then df and get = 1895152 1k blocks 
and indeed 
1993056 - 1895152

sudo e2fsck -f /dev/loop0
sudo resize2fs -M /dev/loop0  (again and again if you like!)
> currently get fs as 269186 blocks long (bloks are 4k).  So to add 100Mb, add 25,000 blocks)
sudo resize2fs -p /dev/loop0 $((269186+25000))
sudo losetup -d /dev/loop0
sudo sync; 

> shrink containing partition: 294186 *4 (to get K).
onekblocks=`echo "294186 * 4" | bc`
fcmd="d \n 2 \n n \n p \n 2 \n 122880 \n +${onekblocks}K \n w"
echo -e $fcmd
echo "Now run: echo -e \$fcmd | fdisk whichever.img"

> Then check truncating the img file itself.
> fdisk says end of p2 is 3322880, and blocks are 512bytes, so truncate:
truncate -s $((3322880*512)) dd.img
zip -r image.zip image.img

done
