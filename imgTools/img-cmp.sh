#!/bin/bash

# mount the partitions p1 and p2 (raspbian) from $1.img.
# do the same for $2.img
# do a diff -r
# umount_image() both
# done.

# include (u)mount_image functions:
. $(dirname $0)/img-utils.sh

[ $# -ne 2 ] && die "img-cmp: Error I need 2 args:  a.img b.img"

imga=$1
imgb=$2
[ -r "$1" ] || die "Error: no such file \"$1\""
[ -r "$2" ] || die "Error: no such file \"$2\""

dira=./a
dirb=./b
[ -d $dira ] && die "Error directory $dira exists. Refusing to overwrite"
[ -d $dirb ] && die "Error directory $dirb exists. Refusing to overwrite"

# mount the image:
mount_image $imga $dira
mount_image $imga $dirb

echo "mounted both."
diff -r $dira $dirb

umount_image $dira
umount_image $dirb

echo "unmounted everything successfully - exiting"

exit 0
