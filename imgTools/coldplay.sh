#!/bin/bash

# travisCI for solo.
# It gets some high level results from a full SD-card
# and prints essential debug.
# it now optionally copies the data to somewhere too.

if [ ! $1 ] ; then
    echo "Usage: coldplay.sh /dev/sdX"
    exit -1
fi
dev=$1
echo "Using device: $dev"
shift

savedir=""
if [ $1 ] ; then
    savedir=/mnt/a/solo/harvested/coldplay/$1
    echo "Will save data to directory \"$savedir\""
fi

# Check none of the partitions are already mounted...
if mount | grep $dev ; then
    echo ERROR: something is mounted already.
    echo Try: sudo umount $dev\*
    exit -1
fi

tmpdir=$(mktemp -u -d /tmp/coldplay.XXXXXX)

echo "Using tmpdir=$tmpdir"
mkdir -p $tmpdir/{p1,p2,p3}
sudo mount ${dev}1 $tmpdir/p1
sudo mount ${dev}2 $tmpdir/p2
sudo mount ${dev}3 $tmpdir/p3

df -h $tmpdir/{p1,p2,p3}

days=$(cd $tmpdir/p3/amondata/wavs ; find . -maxdepth 1 | xargs )
echo "Dates of recording-days were: $days"

lastwav=$(find $tmpdir/p3/amondata/wavs/ | sort -n | tail -1 | sed s:$tmpdir/p3/amondata/wavs/::g)
echo Last recording was called: $lastwav

numwavs=$(find $tmpdir/p3/amondata/wavs/ -name \*.wav -ls | wc -l)
sizewavs=$(find $tmpdir/p3/amondata/wavs/ -name \*.wav -ls | awk '{ sum+=$7 } END {print sum / 1000000}')
echo Recorded $numwavs different wav files totalling $sizewavs MB of audio.

grep "Current default time zone" $tmpdir/p2/opt/solo/solo-boot.log

#echo "arecord.log:"
grep "Recording WAVE" $tmpdir/p3/amondata/logs/arecord.log

#echo WAITING
#read
if [ $savedir ] ; then
    
    if [  -d $savedir ] ; then
	echo "WARNING: savedir $savedir already exists - not copying"
    else
	mkdir -pv $savedir
	echo "copying data from $tmpdir/p3 to $savedir"
	cp -prv $tmpdir/p3/amondata $savedir
    fi
fi

sudo umount $tmpdir/p1
sudo umount $tmpdir/p2
sudo umount $tmpdir/p3

rmdir $tmpdir/{p1,p2,p3}
rmdir $tmpdir/

echo "Finished happily"
