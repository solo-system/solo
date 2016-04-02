Solo
====

Solo is an audio recorder (hardware and software). This repo contains
the tools to build a "solo.img", which is written to the SD card prior
to deploying the Solo.

If you just want to run a Solo (rather than develop better software
for the solo), then you are in the _wrong_ place. Instead, download
the image from here (http://jdmc2.com/e14forum).

## To build your own solo.img

We take an image file from [raspbian](www.raspberrypi.org/downloads),
and modify it to run the software for the Solo field recorder.  The
resulting .img can be flashed to an SD card, placed into the Solo
device and deployed as-is.  Optionally - further config options for
the Solo (channels, sound-source, sampling frequency) are available in
/boot/solo.conf.

This is done by flashing a SD-card with the stock raspbian release,
booting a networked raspberrypi, logging in over ssh, cloning this
repo, and running the script provision.sh.  Then poweroff, move
SD-card back to PC, and copy the modified disk image onto the PC.
This image is now an SRI (Solo Recorder Image), and can be flashed
onto SD-cards to be deployed in the Solo.

Nobody else has ever done it except me and it's messy.  You should
probably get in touch before trying (on the element14 forum).  Have a
look at raspi-install.txt.  And then look at provision.sh.

## Shrinking an .img

Shrinking the solo.img makes it faster to flash to an SD card.

Do this by running shrinkImage.sh, which reduces the size of the "img"
by removing un-necessary space from the p2 (root) partition (left by
purging unneeded packages, and clearing out other un-necessary stuff).
Beware: shrinkImage.sh changes the "img" it's given (on the command
line).  It leaves a certain (few hundred) Mb of space in root
partition for comfort (logs and working space).
