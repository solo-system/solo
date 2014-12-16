#!/bin/bash 

dev=/dev/mmcblk0

echo
echo "using drive: $dev"

# read performance:
echo "Reading:"
dd if=$dev of=/dev/null bs=1M count=50
echo 


echo "WRITE test - WARNING DESTROYS DATA ON DRIVE"

echo "USE WITH CARE - ctrl-C to cancel"
echo "oh - make sure it's not the os partition, or something stupid"

read
echo "checking again.... ARE YOU SURE?"
read

echo "Writing:"
dd of=$dev if=/dev/zero bs=1M count=50
echo 


# this gives the same as above, so pointless.  But it does work.
#echo "now read test using hdparm..."
#hdparm -t $dev

echo "Done."
