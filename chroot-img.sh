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
    rmdir $dir 
    echo "umount_image(): unmounted both partitions and removed dir \"$dir\"."
}

# Parse command line: if $1 exists, it's the command to run inside the chroot.
[ $# -gt 1 ] && die " -e Error: too many command line params. \nUsage: $0 <script-to-run.sh>"
if [ $# -eq 1 ] ; then
    chroot_cmd_cl=$1
    [ -r "$chroot_cmd_cl" ] || die "Error: no such command \"$chroot_cmd_cl\""
    # echo "Parse CMDline: chroot_cmd_cl is now $chroot_cmd_cl"
fi

# check we've got what we need:
[ -x /usr/bin/qemu-arm-static ] || die "Error: need to \"sudo apt-get install qemu-user-static\""
[ -e vroot ] && die "Error: directory vroot already exists.  Refusing to overwrite"

# make sure you copy this before starting - don't point at a master copy.
img=copy.img

[ -r $img ] || die "Error no such image: $img"

# mount the image:
mount_image $img vroot

# Do the things we need to set up the chroot:
sudo mv -v vroot/etc/ld.so.preload vroot/etc/ld.so.preload.dist # no idea why
sudo cp -v /usr/bin/qemu-arm-static vroot/usr/bin/ # qemu virtualises everything we run in there x86(arm)

# copy the chroot_cmd into the mounted directory, putting it in /opt/chroot/ with it's $(basename)
if [ -n "$chroot_cmd_cl" ] ; then
    # echo "need to copy $chroot_cmd_cl into the mounted directory:"
    sudo mkdir -p vroot/opt/chroot/  # -p allows multiple runs, since we don't remove this.
    sudo cp -v $chroot_cmd_cl vroot/opt/chroot/
    chroot_cmd=/opt/chroot/$(basename $chroot_cmd_cl)
else
    chroot_cmd="/bin/bash"
    echo "chroot_cmd unspecified, so defaulted to $chroot_cmd"
fi

echo "Starting chroot ... [cmd=\"$chroot_cmd\"]"
#sudo chroot vroot /bin/bash # ignore all the chroot_cmd stuff and run bash.
sudo chroot vroot $chroot_cmd
echo "... Chroot closed."

# undo the things we needed
sudo mv -v vroot/etc/ld.so.preload.dist vroot/etc/ld.so.preload
sudo rm -v vroot/usr/bin/qemu-arm-static

# TODO - could remove the chroot_cmd from the mounted image, but why bother...
# rm -v vroot/opt/chroot/$chroot_cmd

# and unmount everything
umount_image vroot

exit 0
