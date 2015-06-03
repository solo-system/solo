Solo
====
# Tools to build an ".img" file suitable to run a Solo field recorder.

We take an image file from [raspbian](www.raspberrypi.org/downloads), and produce a modified version which will run the Solo field recorder. 

The instructions to do this are in the file raspi-install.txt.

This is done by flashing a SD-card with the stock raspbian release, booting a networked raspberrypi, logging in over ssh, cloning this repo, and running the script provision.sh.  Then poweroff, move SD-card back to PC, and copy the modified disk image onto the PC.  This image is now an SRI (Solo Recorder Image), and can be flashed onto SD-cards to be deployed in the Solo.

provision.sh performs the following:

1.  Sets up reading the hardware clock to set the time in the Solo
2.  Sets up building third partition (/dev/mmcblk0p3 -> /mnt/sdcard) for all the audio data
3.  adds packages needed to run Solo (via apt-get install ...)
4.  removes un-necessary packages  (via apt-get purge ...)
5.  ensures solo-boot.sh is run at every boot time to do config on the live system.
6.  
5.  

minimize power consumption
4.  add cron job to start and monitor the "amon" audio monitor software
5.  Set the timezone.
6.  Remove unwanted pack
7.  ages

It's done by booting a networked raspberry pi with a stock raspbian release, loggin in, running "provision.sh", whichh puts all these things in place.  We then poweroff and move the SDcard back to a PC to keep it for later flashing.  See raspi-install.sh for notes on the steps to take to do this.

Infact, the output image can be reduced in size by running shrinkImage.sh, which reduces the size of the "img" by removing un-necessary space from the p2 (root) partition (left by purging unneeded packages, and clearing out other un-necessary stuff).  Beware: shrinkImage.sh changes the "img" it's given (on the command line).



It takes a raspbian image and provisions it for the Solo, then
produces a solo.img which can be flashed to and SD card and booted
directly in the raspi.

Nobody except the author has ever used it. But now it is on github, so that might change.

