#!/bin/bash

# mount "img" and run commands within a chrooted quemu-user-static environment"
# WARNING - this works for me.  Use at your own risk.

function die(){
    echo $*
    exit -1
}

function mount_image() {
    if [ $# -ne 2 ] ; then
	echo "Error: mount_image() requires 2 arguments - Exiting (got $*)"
	exit -1
    fi

    img=$1
    if [ ! -w $img ] ; then
	echo "Error: mount_image(): no such writable image file: $img. Exiting."
	exit -1
    fi

    dir=$2
    if [ -e $dir ] ; then
	echo "Error: mount_image(): output $dir already exists - refusing to overwrite. Exiting."
	exit -1
    fi

    # get the offsets from fdisk -l
    p1offset=$(fdisk -l $img | grep ${img}1 | awk '{print $2}')
    p2offset=$(fdisk -l $img | grep ${img}2 | awk '{print $2}')

    mkdir $dir
    sudo mount $img -o loop,offset=$((512*p2offset)) $dir/
    sudo mount $img -o loop,offset=$((512*p1offset)) $dir/boot/

    echo "mount_image(): mounted \"$img\" on \"$dir\" offsets: [p1,$p1offset] [p2,$p2offset]"
    sleep 1 # let things settle (don't run umount_image immediately, it fails).
}

function umount_image() {
    if [ $# -ne 1 ] ; then
	echo "Error: mount_image() requires 1 argument (directory) - Exiting (got $*)"
	exit -1
    fi

    dir=$1
    if [ ! -e $dir ] ; then
	echo "Error: mount_image(): no such directory $dir. Exiting."
	exit -1
    fi

    sudo umount $dir/boot/
    sudo umount $dir/
    sync
    rmdir vroot
    echo "umount_image(): unmounted both partitions and removed dir \"$dir\"."
}

# check we've got what we need:
[ -x /usr/bin/qemu-arm-static ] || die "Error: need to \"sudo apt-get install qemu-user-static\""
[ -e vroot ] && die "Error: directory vroot already exists.  Refusing to overwrite"

# make sure you copy this before starting - don't point at a master copy.
img=copy.img

[ -r $img ] || die "Error no such image: $img"

# mount the image:
mount_image $img vroot

# Do the things we need to set up for the chroot:
sudo mv -v vroot/etc/ld.so.preload vroot/etc/ld.so.preload.dist
sudo cp -v /usr/bin/qemu-arm-static vroot/usr/bin/
sudo cp -v /home/jdmc2/git/solo/pre-provision.sh vroot/opt/

echo "Starting chroot..."
sudo chroot vroot /bin/bash /opt/pre-provision.sh
#sudo chroot vroot /bin/bash
echo "... Chroot closed."

# undo the things we needed
sudo mv -v vroot/etc/ld.so.preload.dist vroot/etc/ld.so.preload
sudo rm -v vroot/usr/bin/qemu-arm-static

# and unmount everything
umount_image vroot

exit 0
