# helper functions for solo-boot.sh

function set_timezone() {
    if [ -n "$SOLO_TZ" ] ; then
	echo "SOLO_TZ is set to $SOLO_TZ"
	echo "/etc/timezone is set to $(cat /etc/timezone)"
	if [ "$SOLO_TZ" != $(cat /etc/timezone) ] ; then
	    echo "Setting /etc/timezone to new tz: $SOLO_TZ ... "
	    echo $SOLO_TZ > /etc/timezone
	    echo "And updating system via rpdk-reconfigure tzdata..."
	    dpkg-reconfigure -f noninteractive tzdata
	else
	    echo "System timezone already matches SOLO_TZ, so doing nothing"
	fi
    else
	echo "SOLO_TZ not set, do doing nothing about /etc/timezone = $(cat /etc/timezone)"
}
