#!/bin/bash

bin=/home/jdmc2/git/solo/imgTools
. $bin/img-utils.sh

[ "$USER" = "root" ] || die "Error: must be root.  Use sudo ..."

daystamp=$(date +"%Y-%m-%d")
stamp=$(date +"%Y-%m-%d.%H-%M-%S")
workdir=/mnt/a/solo/dailyProvision/$stamp
#workdir=/home/jdmc2/solo/chroot/dailyProvision/$stamp

echo "dailyProvision.sh: building an image at $stamp"
echo "workdir: $workdir"
mkdir $workdir

pushd $workdir > /dev/null

#cp /home/jdmc2/solo/foundation-images/2016-05-10-raspbian-jessie-lite.img ./copy.img
cp /home/jdmc2/solo/foundation-images/2016-05-27-raspbian-jessie-lite.img ./copy.img

echo "running: $bin/img-chroot.sh $bin/pre-provision.sh"

$bin/img-chroot.sh ./copy.img $bin/pre-provision.sh >& dailyProvision.log

echo "Finished the provision into $workdir"

echo "now shrinking..."
cp copy.img shrunk.img
$bin/img-shrink.sh -f shrunk.img >> dailyProvision.log 2>&1

echo "changing ownership and permissions (from root to jdmc2) of output files"
sudo chown -R jdmc2.jdmc2  $workdir
sudo chmod u+w $workdir/*

echo "Done img-shrink"

echo "DailyProvision finished. New SOSI is in $workdir/shrunk.img"

echo "Now do helpful things for a release:"
mv -v shrunk.img sosi-$daystamp.img
zip sosi-$daystamp.img.zip sosi-$daystamp.img

sha=$(sha1sum sosi-$daystamp.img.zip)
size=$(stat --format "%s" sosi-$daystamp.img.zip)
sizeMB=$(echo " $size / (1024*1024) " | bc)

solohead=$(cd /home/jdmc2/git/solo ; git rev-parse HEAD)
amonhead=$(cd /home/jdmc2/git/amon ; git rev-parse HEAD)

echo "--------------------------------"
echo "  name: sosi-$daystamp.img"
echo "  sha1sum    : $sha"
echo "  size       : ${sizeMB}MB"
echo "  exact size : $size"
echo "  solo: git rev-parse HEAD: $solohead"
echo "  amon: git rev-parse HEAD: $amonhead"
echo "  This release includes:"
echo "    These things XXXXX"
echo "--------------------------------"

popd > /dev/null

exit 0
