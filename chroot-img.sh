#!/bin/bash

# check we've got what we need:
if [ ! -x /usr/bin/qemu-arm-static ] ; then
    echo "Error: need to install qemu-user-static"
    echo "Use: sudo apt-get install qemu-user-static"
    exit -1
fi

if [ -d vroot ] ; then
    echo "Error: directory vroot already exists.  Refusing to overwrite"
    exit -1
fi

# make sure you copy this before starting - don't point at a master copy.
img=copy.img

# get the offsets from "start" column of output of fdisk -l img.
p1offset=8192
p2offset=137216

# make a dir to mount things in:
mkdir vroot
sudo mount $img -o loop,offset=$((512*p2offset)) vroot/
sudo mount $img -o loop,offset=$((512*p1offset)) vroot/boot/

# remove ld.so.preload:
sudo mv vroot/etc/ld.so.preload vroot/etc/ld.so.preload.dist

# copy qemu-arm-static into the vroot:
sudo cp /usr/bin/qemu-arm-static vroot/usr/bin/

# do the chroot:
echo "would now do : sudo chroot vroot /bin/bash /opt/prov.sh"

#umount vroot/boot
#umount vroot
