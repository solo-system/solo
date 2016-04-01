# this installs CLAC support according to HiassofT's instructions
# it supersedes RJ's in setup-clac.sh

# TODO: could save space removing all the old /lib/modules/{3.18.11+,3.18.11-v7+}
# .. whichever are NOT this kernel's modules.
# and the old kernels too, of course.

echo "Installing Support for HiassofT's CLAC..."

WORKDIR=/tmp/Hiassoft/
mkdir $WORKDIR
pushd $WORKDIR

echo "... fetching [ my copy of ] HiassofT's tar file"
wget jdmc2.com/solo/HiassofT/cirrus-linux-4.1.19.tgz
wget jdmc2.com/solo/HiassofT/usecase-scripts.tgz

echo "... and untarring the kernel files"
tar zxf cirrus-linux-4.1.18.tgz -C /

echo "... and now untarring the use-case scripts"
mkdir -p /home/amon/clac
tar zxf usecase-scripts.tgz -C /home/amon/clac/
chown -R amon:amon /home/amon/clac
chmod +x /home/amon/clac/*.sh

popd # go back to where we were (wherever that was - I don't remember why this was important)

# see http://www.horus.com/~hias/cirrus-driver.html
echo "... Updating /boot/config.txt"
cp /boot/config.txt /boot/config.txt.pre-provision
cat <<EOF >> /boot/config.txt
# Below added by solo's setup-clac-HiassofT.sh
# Add the following line to /boot/config.txt to enable the Cirrus Logic card driver
dtoverlay=rpi-cirrus-wm5102
# If you want MMAP support (eg for Alsa plugins) add this line as well:
dtoverlay=i2s-mmap
EOF


# Setup module dependencies
# The cirrus driver requires some manually defined module dependencies,
# if you fail to add them the driver won't load properly.
# Create a file /etc/modprobe.d/cirrus.conf with the following content:
cat << EOF > /etc/modprobe.d/cirrus.conf
softdep arizona-spi pre: arizona-ldo1
softdep spi-bcm2708 pre: fixed
softdep spi-bcm2835 pre: fixed
EOF

echo "Done Installing CLAC stuff from HiassofT."
