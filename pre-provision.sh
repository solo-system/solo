#!/bin/bash

# Actually, installing git is not the only thing we need.  the default
# resize2fs of p1 at boot time throug /etc/init.d/resize2fs_once
# renders hardware provisioning pretty difficult, as the resulting SDcard
# would need to be dd'd in it's entirety back to your PC and then
# shrunk (using shrinkImage).  Whilst this is possible (tip: use a
# small SD card), it's really ugly.

# The SOLO _really_ does not want (must not have) auto-resizing. So
# remove it here:

# take it out of the boot process (removes the link: /etc/rc3.d/S01resize2fs_once)
# and remove the script, just in case.
update-rc.d resize2fs_once remove
rm /etc/init.d/resize2fs_once

# raspbian lite does NOT have git, and a few other little things.
apt-get update
apt-get install -y git # needed for raspbian "lite" editions.
cd /opt
git clone https://github.com/solosystem/solo.git
cd solo
chmod +x /opt/solo/provision.sh
echo "about to run ./provision.sh..."
./provision.sh
echo "Finished running provision.sh"
echo "Done it all - exit to leave the chroot"
