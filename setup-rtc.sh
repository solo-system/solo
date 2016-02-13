#!/bin/bash

# TODO: don't set up /dev/rtc0 if it already exists
# This could happen if this script is ever called from command line (ie NOT at boot time)
# that might happen if this script gets used (by me or by the system) to SET the RTC somehow...

# WARNING = root filesystem is mounted read-only, so can't output to any logs (or perhaps /var/log is writable - dunno)

ME=setup-rtc.sh
LOG=/var/log/${ME}.log

# put all output into the logfile. NO! can't cos slash is root only.
# actually, this is odd.  I get an error in /var/log/boot when I "touch /var/log/setup-rtc.log" but it works anyway.  (buffered until "remount -rw" or something?)
#exec > $LOG 2>&1

# for the moment, the output of this must go to stdout (captured by bootlogd and ending up in /var/log/boot).

# a wee local logging functin (uses echo/stdout, so honors the exec redirect above)
llog() { echo "$ME [ $(date +'%Y-%m-%d %H-%M-%S') ]: $@" ; } #DONT forget the semicolon

llog "Starting..."

llog "mount output: (root is probably ro if we are booting)"
mount

llog "module listing:"
lsmod

llog "modprobing i2c-dev to see if that works... (can it see / ?)"
modprobe i2c-dev

llog "so now lets lsmod again...:"
lsmod

llog "so lets look at the i2c bus:"
if [ -f /sys/class/i2c-adapter/i2c-1/new_device ] ; then
 llog "YES - i2c bus is there - new_device in particular - here's the otput of find"
fi
find /sys/class/i2c-adapter/i2c-1/

llog "scan the i2c bus:"
i2cdetect -y 1

llog "Try to add the mcp7941x at address 0x6f"
echo mcp7941x 0x6f > /sys/class/i2c-dev/i2c-1/device/new_device

llog "and now run i2cdetect -y 1 again (should see UU)"
i2cdetect -y 1

llog "so lets try to see /dev/rtc0"
ls -l /dev/rtc0

llog "RTC time is (hwclock --show)"
hwclock --show

llog "set system time from rtc... "
hwclock --hctosys

llog "Done setting system time from RTC"

exit 0

