#!/bin/bash

# mount "img" and run commands within a chrooted quemu-user-static environment"
# WARNING - this works for me.  Use at your own risk.

# include (u)mount_image functions:
. $(dirname $0)/img-utils.sh

# Parse command line: Usage:$0 img [cmd]
[ $# -lt 1 -o $# -gt 2 ] && die " -e Error: too many command line params. \nUsage: $0 img <script-to-run.sh>"

img=$1
[ -r $img ] || die "Error no such image: $img"
[ -w $img ] || die "Error \"$img\" not writable."

if [ $# -eq 2 ] ; then
    chroot_cmd_cl=$2
    [ -r "$chroot_cmd_cl" ] || die "Error: no such command \"$chroot_cmd_cl\""
    # echo "Parse CMDline: chroot_cmd_cl is now $chroot_cmd_cl"
fi

# check we've got what we need:
[ -x /usr/bin/qemu-arm-static ] || die "Error: need to \"sudo apt-get install qemu-user-static\""
[ -e vroot ] && die "Error: directory vroot already exists.  Refusing to overwrite"

# right - get on with it.

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

# remove the chroot directory:
rm -rf vroot/opt/chroot

# undo the things we needed
sudo mv -v vroot/etc/ld.so.preload.dist vroot/etc/ld.so.preload
sudo rm -v vroot/usr/bin/qemu-arm-static

# note: - could remove the chroot_cmd from the mounted image, but why bother...
# rm -v vroot/opt/chroot/$chroot_cmd

# and unmount everything
umount_image vroot

exit 0
