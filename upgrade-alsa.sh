#!/bin/bash -ex

# build arecord version 1.1.6 (for high sample rate of 768000Hz).
# -- need to build alsa-lib and alsa-utils
#
# first tested on 2018-07-27 on desktop by JC. (it works!).

# alsa-utils needs these headers: (for amixer, I think)
apt-get install libncurses5 libncurses5-dev

# make a directory to work in:
localalsadir=/opt/upgrade-alsa/

mkdir $localalsadir
echo localalsadir=$localalsadir
cd $localalsadir

# make local install directory for alsa-lib and alsa-utils
mkdir installdir

# get, configure, make, and install alsa-lib (all locally)
wget ftp://ftp.alsa-project.org/pub/lib/alsa-lib-1.1.6.tar.bz2
tar xvfj alsa-lib-1.1.6.tar.bz2
pushd alsa-lib-1.1.6
./configure --prefix=$localalsadir/installdir/
make
make install
popd

echo "Done with alsa-lib, not move on to alsa-utils..."

# get, configure, make, and install alsa-utils (all locally) 
wget ftp://ftp.alsa-project.org/pub/utils/alsa-utils-1.1.6.tar.bz2
tar xvfj alsa-utils-1.1.6.tar.bz2
pushd alsa-utils-1.1.6
./configure --prefix=$localalsadir/installdir/ --with-alsa-prefix=$localalsadir/installdir/lib/ --with-alsa-inc-prefix=$localalsadir/installdir/include/  --with-systemdsystemunitdir=$localalsadir/installdir/systemdfiles/ --with-udev-rules-dir=$localalsadir/installdir/udevrulesdir/
make install
popd

echo "all done - now try running $localalsadir/installdir/bin/arecord --version ..."
$localalsadir/installdir/bin/arecord --version

rm -rf alsa-lib-1.1.6 alsa-lib-1.1.6.tar.bz2 alsa-utils-1.1.6 alsa-utils-1.1.6.tar.bz2 

echo "install-alsa.sh Exiting."
