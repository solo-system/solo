#!/bin/bash

# Copy Card.
# copy a (used?) solo img back from the sdcard reader to the desktop
# using dd, keeping it as a single .img
# it's used to see what changes after a run on the Solo.
# written very quickly on 2018-08-03


dev=/dev/sdf

of=./out.img

# get the address of the end of partition 2.

rootoffset=`fdisk -l $dev | grep ${img}2 | awk '{print $2}';`
p2final=$(sudo fdisk -l /dev/sdf | grep ^$dev | head -2 | tail -1 | awk '{print $3}')

echo $p2final
cmd="sudo dd bs=512 count=$p2final if=$dev of=$of"
echo would run: $cmd
$cmd

ls -l $of

echo "CC Done. Exiting happy"

exit
