solo
====

Tools to build an ".img" file suitable to run a Solo field recorder.

We take a raw raspbian ".img" (downloadable from raspberry pi website) and make lots of changes to it, producing an image file as the output.

It does the following things:

1.  Read the hardware clock to set the time
2.  Build third partition (/dev/mmcblk0p3 -> /mnt/sdcard) for all the audio data
3.  minimize power consumption
4.  add cron job to start and monitor the "amon" audio monitor software
5.  Set the timezone.
6.  Remove unwanted packages

It's done by booting a networked raspberry pi with a stock raspbian release, loggin in, running "provision.sh", whichh puts all these things in place.  We then poweroff and move the SDcard back to a PC to keep it for later flashing.  See raspi-install.sh for notes on the steps to take to do this.

Infact, the output image can be reduced in size by running shrinkImage.sh, which reduces the size of the "img" by removing un-necessary space from the p2 (root) partition (left by purging unneeded packages, and clearing out other un-necessary stuff).  Beware: shrinkImage.sh changes the "img" it's given (on the command line).



It takes a raspbian image and provisions it for the Solo, then
produces a solo.img which can be flashed to and SD card and booted
directly in the raspi.

Nobody except the author has ever used it. But now it is on github, so that might change.

