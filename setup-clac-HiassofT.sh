# this installs CLAC support according to HiassofT's instructions
# it supersedes RJ's in setup-clac.sh

# TODO: remove unused kernels and /lib/modules: rm -rf
# /lib/modules/{3.18.11+,3.18.11-v7+} .. whichever are NOT this
# kernel's modules. (but which is that?)  Tried this: origmodules=$(ls
# /lib/modules) - but still need to take care that HiassofT's aren't
# the same version number - so need to do a wc -l on /lib/modules
# later to see if there is > 2 (one for arm6 one for arm7) - only then
# can we rm -rf $origmoldules.  Too excited to do this cleanup work
# right now - want to try tem out.

# DEBUG: get info from the bootloader? on it's reading of the dtbs and
# overlays: sudo vcdbg log msg
# note it claims: " dtparam: pwr_led_gpio=35"
# - can I control CLAC led's on this pin?

echo "Installing Support for HiassofT's CLAC..."

WORKDIR=/tmp/Hiassoft/
mkdir $WORKDIR
pushd $WORKDIR

# see: https://www.element14.com/community/message/194540/l/re-driver-fixes-and-updates-to-kernel-31816-and-405#194540
echo "need to install rpi-update"
apt-get install rpi-update

echo "before we start, need to do an rpi-update ..."
SKIP_KERNEL=1 rpi-update

echo "... fetching [ my copy of ] HiassofT's tar file"
wget jdmc2.com/solo/HiassofT/cirrus-linux-latest.tgz
wget jdmc2.com/solo/HiassofT/usecase-scripts.tgz

echo "... and untarring the kernel files"
tar zxf cirrus-linux-latest.tgz -C /

echo "... and now untarring the use-case scripts"
mkdir -p /home/amon/clac
tar zxf usecase-scripts.tgz -C /home/amon/clac/
chown -R amon:amon /home/amon/clac
chmod +x /home/amon/clac/*.sh

popd # go back to where we were (wherever that was - I don't remember why this was important)

# 
echo "... Updating /boot/config.txt"
cp /boot/config.txt /boot/config.txt.pre-provision
cat <<EOF >> /boot/config.txt

# Below lines have been added by solo's setup-clac-HiassofT.sh
# see http://www.horus.com/~hias/cirrus-driver.html for details
# Add the following line to /boot/config.txt to enable the Cirrus Logic card driver
dtoverlay=rpi-cirrus-wm5102
# If you want MMAP support (eg for Alsa plugins) add this line as well:
dtoverlay=i2s-mmap
EOF

# Setup module dependencies
# The cirrus driver requires some manually defined module dependencies,
# if you fail to add them the driver won't load properly.
# Create a file /etc/modprobe.d/cirrus.conf with the following content:
cat <<EOF > /etc/modprobe.d/cirrus.conf
# Below lines have been added by solo's setup-clac-HiassofT.sh
# see http://www.horus.com/~hias/cirrus-driver.html for details
softdep arizona-spi pre: arizona-ldo1
softdep spi-bcm2708 pre: fixed
softdep spi-bcm2835 pre: fixed
EOF

echo "Done Installing CLAC stuff from HiassofT."
