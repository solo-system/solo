#!/bin/bash

bin=/home/jdmc2/git/solo/imgTools
. $bin/img-utils.sh

[ "$USER" = "root" ] || die "Error: must be root.  Use sudo ..."

stamp=$(date +"%Y-%m-%d.%H-%M-%S")
#workdir=/mnt/a/dailyProvision/$stamp
workdir=/home/jdmc2/solo/chroot/dailyProvision/$stamp

echo "dailyProvision.sh: building an image at $stamp"
echo "workdir: $workdir"
mkdir $workdir

pushd $workdir > /dev/null

cp /home/jdmc2/solo/foundation-images/2016-05-10-raspbian-jessie-lite.img ./copy.img

echo "running: $bin/img-chroot.sh $bin/pre-provision.sh"

$bin/img-chroot.sh ./copy.img $bin/pre-provision.sh >& dailyProvision.log

echo "New SOSI is in $workdir"

echo "makeing copy to shrink"
cp copy.img shrunk.img

echo "shrinking"
$bin/img-shrink.sh -f shrunk.img
# mv shrunk.img solo-$stamp.img - nah keep the shrunk.img name

echo "changing ownership and permissions (from root to jdmc2) of output files"
sudo chown -R jdmc2.jdmc2  /home/jdmc2/solo/chroot/dailyProvision/$stamp
sudo chmod u+w /home/jdmc2/solo/chroot/dailyProvision/$stamp/*

echo "Done shrinkImaging it".

echo "done.  New SOSI is in $workdir/$stamp.img"

popd > /dev/null

exit 0
