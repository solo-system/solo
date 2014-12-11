#!/bin/bash

echo 
echo 
echo "*** This is test-RTC - tests the operation, and sets the RTC"
echo
echo "Current system time is :"


echo "Looking for RTC... ( checking /dev/rtc0)"

if [ ! -c /dev/rtc0 ] ; then
    echo "No such file - /dev/rtc0"
    echo "exiting..."
    exit -1
fi

sysdate=`date`
rtcdate=`/sbin/hwclock --show`
netdate=`rdate -p time.nist.gov`

echo "sysdate: $sysdate"
echo "rtcdate: $rtcdate"
echo "netdate: $netdate"


exit 0
