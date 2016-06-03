#!/bin/bash

bin=/home/jdmc2/git/solo/imgTools
. $bin/img-utils.sh

[ "$USER" = "root" ] || die "Error: must be root.  Use sudo ..."

stamp=$(date +"%Y-%m-%d.%H-%M-%S")
workdir=/mnt/a/solo/dailyProvision/$stamp
#workdir=/home/jdmc2/solo/chroot/dailyProvision/$stamp

echo "dailyProvision.sh: building an image at $stamp"
echo "workdir: $workdir"
mkdir $workdir

pushd $workdir > /dev/null

cp /home/jdmc2/solo/foundation-images/2016-05-10-raspbian-jessie-lite.img ./copy.img

echo "running: $bin/img-chroot.sh $bin/pre-provision.sh"

$bin/img-chroot.sh ./copy.img $bin/pre-provision.sh >& dailyProvision.log

echo "Finished the provision into $workdir"

echo "now shrinking..."
cp copy.img shrunk.img
$bin/img-shrink.sh -f shrunk.img >> dailyProvisin.log 2>&1

echo "changing ownership and permissions (from root to jdmc2) of output files"
sudo chown -R jdmc2.jdmc2  $workdir
sudo chmod u+w $workdir/*

echo "Done img-shrink"

echo "DailyProvision finished. New SOSI is in $workdir/shrunk.img"

popd > /dev/null

exit 0
