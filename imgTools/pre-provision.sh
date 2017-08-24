#!/bin/bash

# show what we are doing.
set -x

# you can't merge this with provision.sh, cos you need to clone
# solo.git before you can run provision.sh.  Needs 2 stages.

# pre-provision used to be run by hand (on the pi) to do things like
# install git, which was needed to then download provision.sh.  It
# became a script, and now that we do it all in qemu, it should really
# be merged.

echo "hello - I am the pre-provisioner.  I run things inside the chroot, prior to handing over to provision.sh"

# raspbian lite does NOT have git, and a few other little things.
echo "do a apt-get update and apt-get install -y git."
apt-get update
apt-get install -y git # needed for raspbian "lite" editions.
echo
echo "Now cloning github.com/solosystem/solo.git into /opt/"
#echo "NOTE: the following hangs occasionally - so... do stuff to excercise link to github and to use git..."
#ping -c3 github.com
#git status
#echo "Done - that might help..."

cd /opt
git clone http://github.com/solosystem/solo.git
#git clone https://github.com/solosystem/solo.git
cd solo
chmod +x /opt/solo/imgTools/provision.sh

echo "about to run imgTools/provision.sh..."
imgTools/provision.sh # something on stdin eats the input
echo "Finished running provision.sh"

echo "Clearing out /var/log..."
rm -rfv /var/log/*

echo "Done it all - exit to leave the chroot"
