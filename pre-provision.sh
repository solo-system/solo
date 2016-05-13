#!/bin/bash

# raspbian lite does NOT have git, and a few other little things.
apt-get update
apt-get install -y git # needed for raspbian "lite" editions.
cd /opt
git clone https://github.com/solosystem/solo.git
cd solo
chmod +x /opt/solo/provision.sh
./provision.sh   # this does a lot so have a cup of tea.
echo "Done it all - exit to leave the chroot"
