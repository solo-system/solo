#!/bin/bash

######################################################################
# Job is to take an .img file and shrink the "root" partition within
# it.  We assume here that there is lots of space within that
# partition
#
# Algorthm is in 3 bits:
# First:  the ext fs - minimize then add-a-bit-of-free-space
# Second: is the MBR/partition table.
# Third:  is the truncation of the img file itself.
######################################################################

# resize2fs doesn't give you the free space you might think:
# (and all this is WITHOUT rebuilding the journal, which takes 32786 * (1k) = 32Mb.
# Asked  fs-size (df)	free(1k)	Difference.
# 400M   1350852          332436	68M less than asked-for <- 332Mb free - choose as dflt)
# 200M   1154964          147312   	53M less than asked-for
# 100M   1054964           52312   	48M less than asked-for
# 64M    1021016           20164   	44M less than asked-for
# 48M    1005016            4964 	43M less than asked-for
# 40M     997016               0 	40M less than asked-for
# SEE BELOW on what we actually use.

# -f on command line overrules "are you sure?"
if [ $# -eq 2 -a "$1" = "-f" ] ; then
   force=yes
   echo force is on
   shift
fi
   
if [ $# -ne 1 ] ; then
    echo "Error: must prescribe img file on command line"
    exit -1
fi

img=$1

if [ ! -f "$img" ] ; then
    echo "Error: no such file $img"
    exit -1
fi

if [ ! -f $img ] ; then
    echo "Error - no such image $img"
    exit -1
fi

if [ ! -w $img ] ; then
    echo "Error - image not writable: $img"
    exit -1
fi

# pause for user confirmation if not forced
if [ -z "$force" ] ; then
    echo "About to shrink: $img"
    echo "WARNING *** This program changes the input file !!! ***"
    echo "press return to continue ... WAITING (or ctrl-c to bail out)"
    read
fi

# how many extra 4k blocks to add to the FS: (see info at top of file)
extra4k=100000  # ask for 400M
extra4k=25000   # ask for 100M - only yields 21Mb free.
extra4k=50000   # ask for 200M - this yeilds 111Mb free (use this).
                # at 200M, the img size is 1,279,132,160 and zip is 419,739,504

function log() {
    msg="$1"
    out="[SHRINK IMAGE]: $msg"
    echo "$out"
}

# We only need access to partiton 2 (root):
rootoffset=`fdisk -l $img | grep ${img}2 | awk '{print $2}';`
log "root partition starts at: $rootoffset"

log "setting up loop with offset..."
sudo losetup -v -o $(($rootoffset*512)) /dev/loop0 $img  # build a device.

log "fscking filesystem before we even start..."
sudo e2fsck -p -f /dev/loop0  # do this a lot to keep sane.

log "removing journal..."
sudo tune2fs -O ^has_journal /dev/loop0 #get rid of journal prior to resize.

log "fscking again to be paranoid (just after journal removal)"
sudo e2fsck -p -f /dev/loop0

log "resizing to minimum size [TAKES TIME] ..."
sudo resize2fs -M /dev/loop0  # do the resize to the minimum sixe

log "checking fs again... (after shrinking to minimum size)"
sudo e2fsck -p -f /dev/loop0

log "Finding size of minimized fs:"
minsize4k=$(sudo dumpe2fs /dev/loop0 | grep "Block count:" | awk '{print $3}')
targetsize4k=$((minsize4k + extra4k)) # the extra space
log "minsize = $minsize4k (4kb).  Adding $extra4k (4k) -> target size of $targetsize4k"

log "resizing to desired size of $targetsize4k..."
sudo resize2fs -p /dev/loop0 $targetsize4k

log "Finding new size of fs:"
newsize4k=$(sudo dumpe2fs /dev/loop0 | grep "Block count:" | awk '{print $3}')
newsize1k=$((newsize4k * 4))
newsizehalfk=$((newsize1k * 2)) #this is in 512 byte blocks (half-k)
log "Final size of fs is $newsize4k (4k blocks), or $newsize1k (1k blocks) or $newsizehalfk (half-k blocks)"

log "Rebuilding the journal..."
sudo tune2fs -j /dev/loop0

log "and a final fsck... (just before we unload /dev/loop0)"
sudo e2fsck -p -f /dev/loop0      

log "syncing disks..."
sync # paranoia

log  "removing /dev/loop0"
sudo losetup -d /dev/loop0

log "done with all the stuff at fs level - now doing MBR/partition stuff..."

log "Doing the partition table shrink..."
log "BUG: if we hand fdisk a +XXX partition size for p2, it does less.  So we need to add"
log ".... a bit on to compensate.  Currently (2017-06-14) we are adding 70 4-k blocks (560 halfk-blocks)."
newsizehalfk2=$((newsizehalfk + 560))
log " so rather than using $newsizehalfk, we're gonna use $newsizehalfk2"

# now we want to resize the partition in the MBR
# "delete partn,  2, new, 2, primary, rootoffset, +size, w"
fcmd="d\n2\nn\np\n2\n$rootoffset\n+${newsizehalfk2}\nw\n"
echo "about to put this into fdisk: $fcmd..."
echo -e $fcmd | fdisk $img

log "Done partition table shrink... Table now looks like:"
sudo fdisk -l $img

# when I did this "exactly" I was off by one:
# EXT4-fs (loop0): bad geometry: block count 285148 exceeds size of device (285147 blocks)
# so add one 512k block - and that fixes it - Yay!
# BUT then found another bug (months later), and this could be unnecessary now (haven't checked)
# And now I am back again about a year after all that... (2017-06-14), and I get this:
# EXT4-fs (loop0): bad geometry: block count 211782 exceeds size of device (211712 blocks)
# Note that this took AGES to find (since I trusted shring-img and thought it was a kernel-not-booting issue).
# This maths is 70 4-k blocks away from being correct (280kbytes = 560 half-k blocks off.) 


log "now done with the MBR/partition table level stuff - now truncate the .img file"
lastpartoffset=`fdisk -l $img | grep ${img}2 | awk '{print $3}';`
truncatesize=$(((lastpartoffset+1)*512))
log "truncating to $lastpartoffset * 512 bytes = $truncatesize"
truncate -s $truncatesize $img

log "truncate done - ls -l $img:"
ls -l $img

#log "now zipping..."
# zip $img.zip $img

echo "-------------------------------------------------------"
echo "examine new ext2 contents with:"
echo "mkdir p1 && sudo mount -o loop,offset=\$((  8192*512)) $img p1"
echo "mkdir p2 && sudo mount -o loop,offset=\$(($rootoffset*512)) $img p2"
echo "Or check for stray dev/loops with losetup -a"
echo "--------------------------------------------------------"
echo "Finished shrinking $img into $img.zip"
echo "zip it with: zip $img.zip $img"
ls -l $img
echo "Exiting happy."

exit 0

# Using : dumpe2fs /dev/loop0 gives:
# Block count:              234122
# Block size:               4096
# The top number matches the size given out by the resize2fs tool. Yay
# - we don't need to sweep for it.
