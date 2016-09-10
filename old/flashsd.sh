#!/bin/bash -e

# [more] safely flash an "img" to an SD card.

# The whole point of this is to more safely flash SD cards on linux
# (from command line).  With /dev/sd{a,b,c} full of all my important
# data, it scares me every time I dd onto /dev/sdd.

# I am also bored of ensuring that /dev/sdd{1,2,3?} are unmounted
# before flashing.  This should warn of that.

# 

img=/home/jdmc2/solo/foundation-images/2016-03-18-raspbian-jessie-lite.img

ls /sys/block | tac | while read id ; do
    echo "trying $id - is it removable?"
    if [ $(cat /sys/block/$id/removable) == "1" ] ; then
	echo /dev/$id is removable
    else
        echo /dev/$id is NOT removable - bailing out.
	continue
    fi

    # now see if it is in mount
    if mount | grep "/dev/$id"; then
	echo "unfortunately, it's mounted - bailing out"
	continue
    else
	echo "and none of it's partitions are mounted - so still good"
    fi

    echo "got good candidate: /dev/$id"
    export $id
done

echo Chosen /dev/$id
