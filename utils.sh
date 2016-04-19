# helper functions for solo-boot.sh

function header() {
    echo ""
    echo "============================================="
    echo " Started:  $1 [at $(date)]"
}

function footer() {
    echo " Finised:  $1 [at $(date)]"
    echo "============================================="
    echo ""
}

function logit() {
    echo "... $* [at $(date)]"
}

function minimize_power() {
    header "Minimizing power usage..."
    echo "... disabling tvservice to save power [/opt/vc/bin/tvservice off]"
    /opt/vc/bin/tvservice -off
    footer "Minimizing power usage..."
}

function set_timezone() {
    header "Setting the timezone"
    SYS_TZ=$(cat /etc/timezone)
    echo "... current /etc/timezone is set to $SYS_TZ"
    if [ -n "$SOLO_TZ" ] ; then
	echo "... SOLO_TZ is set to $SOLO_TZ (in solo.conf)"
	if [ "$SOLO_TZ" != "SYS_TZ" ] ; then
	    echo "... setting /etc/timezone to new tz: $SOLO_TZ ... "
	    echo $SOLO_TZ > /etc/timezone
	    echo "... and updating system via dpdk-reconfigure tzdata..."
	    dpkg-reconfigure -f noninteractive tzdata
	else
	    echo "... system timezone already matches SOLO_TZ, so doing nothing"
	fi
    else
	echo "... SOLO_TZ not set in solo.conf so doing nothing about /etc/timezone = $SYS_TZ"
    fi
    footer "Setting the timezone"
}

function setup_leds() {
    header "Setting up the leds"
    if [ $RPINAME = "B+" -o $RPINAME = "A+" -o $RPINAME = "PI2B" ] ; then
	echo "... activating LEDs - led0[green] = heartbeat, led1[red] off"
	echo heartbeat > /sys/class/leds/led0/trigger # heartbeat on green LED
	echo none      > /sys/class/leds/led1/trigger # turn off the red LED
    else
	echo "... don't know how to set LEDs on this hardware: $RPINAME"
	ls -l /sys/class/leds/
	echo "... please update github.com/solosystem/solo/utils.sh"
    fi
    footer "Setting up the leds"
}
