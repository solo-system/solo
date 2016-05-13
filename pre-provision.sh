#!/bin/bash

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
