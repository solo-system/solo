#!/bin/bash

# called from /etc/init.d/hwclock.sh
# it sets up the RTC on your system.  
# written in a hurry - there is no error checking and no scope to support different clocks.
# it does only the piface-shim at address 0x6f
# use logsave utility to keep output, since / is readonly.

# TODO: don't set up /dev/rtc0 if it already exists
# This could happen if this script is ever called from command line (ie NOT at boot time)
# that might happen if this script gets used (by me or by the system) to SET the RTC somehow...

# WARNING = root filesystem is mounted read-only, so can't output to
# any logs (or perhaps /var/log is writable - dunno)

# after changing this file we need to do the following, to get the symlinks right:
# update-rc.d hwclock.sh remove
# update-rc.d hwclock.sh defaults

# this is because I added runlevel 2 (originally only S), and
# update-rc.d WONT update, only install.  So remove then set defaults
# (default refers to the runlevels in the script).  Having been clean
# a few months ago, this is all a bit of a hack now.  

ME=setup-rtc.sh
LOG=/var/log/${ME}.log

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
