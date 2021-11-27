# useful functions for handling filesystem images (p1 and p2 of
# raspbian, for now).

# TODO: could check whether "umount" will fail, but looking for fuser and lsof:
# https://www.systutorials.com/239761/force-linux-unmount-filesystem-reporting-device-busy/

function die(){
    echo $(basename $0): $*
    exit -1
}


# mount p1 (/boot) and p2 (/) from an .img - respect the img file
# permissions - if it isn't writable, mount readonly (even though we
# are root).

function mount_image() {
    [ $# -eq 2 ] || die "Error: mount_image() requires 2 arguments - Exiting (got $*)"

    img=$1
    mount_opts="loop"
    [ -b $img -o -f $img ] || die "Error: mount_image(): no such image file: $img. Exiting."

    if [ ! -w $img ] ; then
	# echo "image not writable ... mounting read-only"
	mount_opts="loop,ro"
    fi

    dir=$2
    if [ -e $dir ] ; then
	echo "Error: mount_image(): output $dir already exists - refusing to overwrite. Exiting."
	exit -1
    fi

    # get the offsets from fdisk -l
    # added the 'tr' to remove the "*" which indicates "bootable"
    p1offset=$(fdisk -l $img | grep ${img}1 | tr '*' ' ' | awk '{print $2}')
    p2offset=$(fdisk -l $img | grep ${img}2 | awk '{print $2}')

    # updated 2017-08-10 - need #sectors now too, or mount complains of "overlapping loop device"
    p1size=$(fdisk -l $img | grep ${img}1 | awk '{print $4}')
    p2size=$(fdisk -l $img | grep ${img}2 | awk '{print $4}')

    # echo p1offset=$p1offset, p2offset=$p2offset
    # echo p1size=$p1size, p2size=$p2size
    
    mkdir $dir
    sudo mount $img -o ${mount_opts},offset=$((512*p2offset)),sizelimit=$((512*p2size)) $dir/
    sudo mount $img -o ${mount_opts},offset=$((512*p1offset)),sizelimit=$((512*p1size))  $dir/boot/
    
    echo "mount_image(): $img mounted on $dir with [p1,$p1offset,$p1size] [p2,$p2offset,$p2size], opts=$mount_opts"
    sleep 1 # let things settle (don't run umount_image immediately, it fails).
}

# undo the mount above (and remove the directory)
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
