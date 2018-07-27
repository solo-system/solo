#!/bin/bash -ex

# build arecord version 1.1.6 (for high sample rate of 768000Hz).
# -- need to build alsa-lib and alsa-utils
#
# first tested on 2018-07-27 on desktop by JC. (it works!).

# alsa-utils needs these headers:
# libncurses(-dev) for or amixer, I think.
# and gettext for i18n within alsa-utils (multilingual stuff).
apt-get -y install libncurses5 libncurses5-dev gettext

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

# NOTES: The rm above removes all the source directories.  The
# "installdir" left over, is everything that the two alsa modules
# (-lib and -utils) wanted to install. We get away with just adding
# /opt/upgrade-alsa/installdir/bin to amon's path (for access to the
# -utils tools - including arecord - the most important), but there
# are a few other things in "installdir" that are noteworthy...

# udevrulesdir - should (but doesn't) overwrite /lib/udev/rules.d/90-alsa-restore.rules
#  - this is to do with udev. Not much different from stock one that comes with default alsa install.  So I'm leaving it uninstalled.

# systemdfiles - again, without really exploring, I am leaving these here without installing them to the system.
# I suppose it's bad to have 2 versions of alsa lying around - particularly when the "system" is using old-alsa to do system things (like restore etc...) and I am using new-alsa, but they are close enough in versions (1.1.3 versus 1.1.6 that it hopefully won't matter).

# written on 2018-07-27.  Looking forward to future versions of raspbian where all this can go away, because stock version of alsa-utils will be 1.1.6. Looks like that's happening in "buster".
