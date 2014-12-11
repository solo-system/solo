#!/bin/bash

echo 
echo 
echo "*** This is test-RTC - tests the operation, and sets the RTC"
echo
echo "Current system time is :"
date

echo "Looking for RTC... ( checking /dev/rtc0)"

if [ ! -c /dev/rtc0 ] ; then
    echo "No such file - /dev/rtc0"
    echo "exiting..."
    exit -1
fi

rdate -s time.nist.gov

exit 0
