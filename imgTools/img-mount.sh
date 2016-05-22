#!/bin/bash

# mount the partitions p1 and p2 (raspbian) from copy.img, then pause,
# then exit.

# include (u)mount_image functions:
. $(dirname $0)/img-utils.sh

# Don't put this on the command line, as I'll inevitably point at a
# "master" copy, screw it up, and not work it out for weeks.  Instead
# insist on a local one called copy.img:
img=copy.img
dir=vroot

[ -e $dir ] && die "Error: directory $dir exists.  Refusing to overwrite"
[ -r $img ] || die "Error no such image: $img"

# mount the image:
mount_image $img $dir

echo "filesystem is in: $(pwd)/$dir"
echo "WAITING: press return to umount"
read

umount_image $dir

exit 0
