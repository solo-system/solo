#!/bin/bash

# travis CI for solo - so it's called coldplay, coz they is both
# famous pop bands in the hit parade.  innit?

dev=sdh

if mount | grep sdh ; then
    echo ERROR: something is mounted already.
    echo Try: sudo umount /dev/$dev\*
    exit -1
fi

tmpdir=$(mktemp -u -d /tmp/coldplay.XXXXXX)

echo "Using tmpdir=$tmpdir"
mkdir $tmpdir

mkdir $tmpdir/p1 $tmpdir/p2 $tmpdir/p3

sudo mount /dev/sdh1 $tmpdir/p1
sudo mount /dev/sdh2 $tmpdir/p2
sudo mount /dev/sdh3 $tmpdir/p3

df -h $tmpdir/{p1,p2,p3}

days=$(cd $tmpdir/p3/amondata/wavs ; find . -maxdepth 1 | xargs )
echo "Dates of recording-days were: $days"

lastwav=$(find $tmpdir/p3/amondata/wavs/ | sort -n | tail -1 | sed s:$tmpdir/p3/amondata/wavs/::g)
echo Last recording was called: $lastwav

numwavs=$(find $tmpdir/p3/amondata/wavs/ -name \*.wav -ls | wc -l)
sizewavs=$(find $tmpdir/p3/amondata/wavs/ -name \*.wav -ls | awk '{ sum+=$7 } END {print sum / 1000000}')
echo Recorded $numwavs different wav files totalling $sizewavs MB of audio.

echo "Timezone information:"
grep "Current default time zone" $tmpdir/p2/opt/solo/solo-boot.log

echo "arecord.log:"
grep "Recording WAVE" $tmpdir/p3/amondata/logs/arecord.log

#echo WAITING
#read

sudo umount $tmpdir/p1
sudo umount $tmpdir/p2
sudo umount $tmpdir/p3

rmdir $tmpdir/{p1,p2,p3}
rmdir $tmpdir/

echo "Finished happily"
