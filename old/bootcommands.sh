#!/bin/bash

echo "welcome to /rc.local.recorder"
echo

echo "about to run firstboot"
/root/firstboot.sh >> /root/firstboot.log 2>&1
echo "done running first boot (see /root/firstboot.log)"
echo
echo "setting up the i2c bus to recognise the rtc"
echo ds1307 0x68 > /sys/class/i2c-adapter/i2c-1/new_device
echo ds1307 0x68 > /sys/class/i2c-adapter/i2c-0/new_device
echo "done setting up i2c for rtc"

echo "setting up the switchoff script"
/root/switchoff.py &

echo "turning off tvservice"
/opt/vc/bin/tvservice -off

echo "setting default volume"
amixer -q -c 1 set "Mic" 15dB

echo "reading the hw clock into system time"
/sbin/hwclock -s || true

echo
echo "Exiting happy from rc.local.recorder"

exit 0
