#!/bin/bash

# This script automatically builds a SOSI from a raspbian.img

bin=/home/jdmc2/git/solo/imgTools
PATH=$PATH:$bin

. $bin/img-utils.sh
[ "$USER" = "root" ] || die "Error: must be root.  Use sudo ..."

daystamp=$(date +"%Y-%m-%d")
stamp=$(date +"%Y-%m-%d.%H-%M-%S")
workdir=/mnt/a/solo/dailyProvision/$stamp

# which version of raspbian to we base this SOSI from?
#srcimg=/home/jdmc2/solo/foundation-images/2016-05-10-raspbian-jessie-lite.img
#PREVGOOD srcimg=/home/jdmc2/solo/foundation-images/2016-05-27-raspbian-jessie-lite.img
#srcimg=/home/jdmc2/solo/foundation-images/2016-09-23-raspbian-jessie-lite.img
#srcimg=/home/jdmc2/solo/foundation-images/2017-04-10-raspbian-jessie-lite.img
#srcimg=/home/jdmc2/solo/foundation-images/2017-07-05-raspbian-jessie-lite.img
#srcimg=/home/jdmc2/solo/foundation-images/2017-08-16-raspbian-stretch-lite.img
#srcimg=/mnt/a/solo/foundation-images/2017-11-29-raspbian-stretch-lite.img
#srcimg=/mnt/a/solo/foundation-images/2018-06-27-raspbian-stretch-lite.img
#srcimg=/mnt/a/solo/foundation-images/2018-10-09-raspbian-stretch-lite.img
#srcimg=/mnt/a/solo/foundation-images/2018-11-13-raspbian-stretch-lite.img
#srcimg=/mnt/a/solo/foundation-images/2019-04-08-raspbian-stretch-lite.img
#srcimg=/mnt/a/solo/foundation-images/2019-07-10-raspbian-buster-lite.img
srcimg=/mnt/a/solo/foundation-images/2022-01-28-raspios-bullseye-armhf-lite.img

echo "dailyProvision.sh: building a SOSI image at $stamp"
echo "workdir: $workdir"
echo "basing this SOSI on $srcimg"

mkdir -p $workdir
pushd $workdir > /dev/null

echo "running: $bin/img-chroot.sh $bin/pre-provision.sh"
cp $srcimg ./copy.img
$bin/img-chroot.sh ./copy.img $bin/pre-provision.sh >& dailyProvision.log
echo "dailyProvision: Finished pre-provision.sh"
echo

echo "Now shrinking ..."
cp -v copy.img shrunk.img
$bin/img-shrink.sh -f shrunk.img >> dailyProvision.log 2>&1
echo "dailyProvision: Done shrinking"

# Change some owners (from root to me)
sudo chown -R jdmc2.jdmc2  $workdir
sudo chmod u+w $workdir/*
mv -v shrunk.img sosi-$daystamp.img

zip sosi-$daystamp.img.zip sosi-$daystamp.img

echo "------------------------------------------------------------"
echo "Done - here's some helpful info for a release:"

sha=$(sha1sum sosi-$daystamp.img.zip)
size=$(stat --format "%s" sosi-$daystamp.img.zip)
sizeMB=$(echo " $size / (1024*1024) " | bc)
solohead=$(cd /home/jdmc2/git/solo ; git rev-parse HEAD)
amonhead=$(cd /home/jdmc2/git/amon ; git rev-parse HEAD)

(
echo "--------------------------------"
echo "  name       : sosi-$daystamp.img"
echo "  raspbian   : This SOSI is based on $(basename $srcimg)"
echo "  sha1sum    : $sha"
echo "  size       : ${sizeMB}MB"
echo "  exact size : $size"
echo "  solo       : git rev-parse HEAD: $solohead"
echo "  amon       : git rev-parse HEAD: $amonhead"
echo "  buildtime  : $stamp"
echo "  This release includes:"
echo "    These things XXXXX"
echo "--------------------------------"
) > sosi-version.txt

cat sosi-version.txt

echo "remounting to get file list, and add sosi-version.txt.."
mount_image sosi-$daystamp.img vroot
find  vroot -type f -ls | sort -nr -k7 > filelist.txt
cp sosi-version.txt vroot/boot/solo/
umount_image vroot
echo "dailyProvision: Completed final umount. Exiting happy."
popd > /dev/null

exit 0
