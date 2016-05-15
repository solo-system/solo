# useful functions for handling filesystem images (p1 and p2 of
# raspbian, for now).

function die(){
    echo $*
    exit -1
}

# mount p1 (/boot) and p2 (/) from an .img 
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

