# This is the third round of config for the CLAC written on 2017-08-10
# the good news (should have been) that the CLAC drivers are now native in the rpi kernel.
# but the bad news came simultaneously that Cirrus are no longer making the card.
# so I'm in a mixed mood as I write this new file.

# I'm following:
# http://www.horus.com/~hias/cirrus-driver.html

echo "Installing Support for HiassofT's CLAC... (version3 - with native drivers)"

# Don't know why we go to this place (copied over from v2)
WORKDIR=/tmp/Hiassoft/
mkdir $WORKDIR
pushd $WORKDIR

echo "... fetching [ my copy of ] HiassofT's tar file"
wget jdmc2.com/solo/HiassofT/cirrus-ng-scripts.tgz

echo "... and now untarring the use-case scripts"
mkdir -p /home/amon/clac
tar zxf cirrus-ng-scripts.tgz -C /home/amon/clac/
chown -R amon:amon /home/amon/clac
chmod +x /home/amon/clac/*.sh

# remove the tarballs
rm cirrus-ng-scripts.tgz

popd # go back to where we were (wherever that was - I don't remember why this was important)

# 
echo "... Updating /boot/config.txt"
cp /boot/config.txt /boot/config.txt.pre-CLAC-config
cat <<EOF >> /boot/config.txt

# Below lines have been added by solo's setup-clac-HiassofT.sh
# see http://www.horus.com/~hias/cirrus-driver.html for details
# Add the following line to /boot/config.txt to enable the Cirrus Logic card driver
dtoverlay=rpi-cirrus-wm5102
EOF

# Setup module dependencies
# The cirrus driver requires some manually defined module dependencies,
# if you fail to add them the driver won't load properly.
# Create a file /etc/modprobe.d/cirrus.conf with the following content:
cat <<EOF > /etc/modprobe.d/cirrus.conf
# Below lines have been added by solo's setup-clac-HiassofT.sh
# see http://www.horus.com/~hias/cirrus-driver.html for details
softdep arizona-spi pre: arizona-ldo1
EOF

rm -rf  $WORKDIR

echo "Done Installing CLAC stuff from HiassofT."
