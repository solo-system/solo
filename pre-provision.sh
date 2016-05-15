#!/bin/bash

# Actually, installing git is not the only thing we need.  the default
# resize2fs of p1 at boot time throug /etc/init.d/resize2fs_once
# renders hardware provisioning pretty difficult, as the resulting SDcard
# would need to be dd'd in it's entirety back to your PC and then
# shrunk (using shrinkImage).  Whilst this is possible (tip: use a
# small SD card), it's really ugly.

echo
echo "hello - I am the pre-provisioner.  I run things inside the chroot.  I do things to the mounted p1/p2 partitions, before handing over to provision.sh"
echo "previously, provision.sh was runnable on a hardware (real) pi, but no it isn't (because of expand_rootfs_once).  Perhaps pre-provision.sh can be merged into provision.sh"
echo



# The SOLO _really_ does not want (must not have) auto-resizing. So
# remove it here:

# take it out of the boot process (removes the link: /etc/rc3.d/S01resize2fs_once)
# and remove the script, just in case.
echo "remove resize2fs_once from boot process..."
update-rc.d resize2fs_once remove
echo "and remove the script to do it, just in case..."
rm /etc/init.d/resize2fs_once

# raspbian lite does NOT have git, and a few other little things.
echo "do a apt-get update and apt-get install -y git."
apt-get update
apt-get install -y git # needed for raspbian "lite" editions.
echo "cloning github.com/solosystem/solo.git into /opt/
cd /opt
git clone https://github.com/solosystem/solo.git
cd solo
chmod +x /opt/solo/provision.sh
echo "about to run ./provision.sh..."
echo "NOT running ./provision.sh
echo "Finished running provision.sh"
echo "Done it all - exit to leave the chroot"
