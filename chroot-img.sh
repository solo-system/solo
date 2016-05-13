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

if [ ! -r $img ] ; then echo "Error no such image: $img"; exit -1; fi


# get the offsets from "start" column of output of fdisk -l img.
p1offset=8192
p2offset=137216

# make a dir to mount things in:
mkdir -v vroot
echo "doing the mounts..."
sudo mount $img -o loop,offset=$((512*p2offset)) vroot/
sudo mount $img -o loop,offset=$((512*p1offset)) vroot/boot/
echo "Done the mounts"

# remove ld.so.preload:
sudo mv vroot/etc/ld.so.preload vroot/etc/ld.so.preload.dist
echo "fiddled ld.so.preload"

# copy qemu-arm-static into the vroot:
sudo cp /usr/bin/qemu-arm-static vroot/usr/bin/
echo "installed qemu-arm-static"

echo "copy over the pre-provision.sh script"
sudo cp -v /home/jdmc2/git/solo/pre-provision.sh vroot/opt/

echo "about to start the chroot..."
# do the chroot:
sudo chroot vroot /bin/bash /opt/pre-provision.sh
echo "Closing down the chroot..."

# reinstate ld.so.preload:
echo "reinstating ld.so.preload"
sudo mv vroot/etc/ld.so.preload.dist vroot/etc/ld.so.preload

# and remove the qemu-arm-static
echo "removing qemu-arm-static"
sudo rm vroot/usr/bin/qemu-arm-static

echo "unmounting..."
sudo umount vroot/boot
sudo umount vroot

rmdir -v vroot

echo "chroot-img exiting HAPPY"
