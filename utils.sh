# helper functions for solo-boot.sh

function header() {
    echo ""
    echo "============================================="
    echo "=== Started:  $1 [at $(date)]"
}

function footer() {
    echo "=== Finised:  $1 [at $(date)]"
    echo "============================================="
    echo ""
}

function logit() {
    echo "... $* [at $(date)]"
}


# stop the resize done by raspbian (as of 2016-05-ish):
function disable_auto_resize() {
    header "Disabling resize2fs in raspbian"

    echo "Changing /boot/cmdline.txt to remove init_resize.sh."
    #    sed -i 's/ quiet init=.*$//' /boot/cmdline.txt # this _used to be the way...
    sed -i 's| init=/usr/lib/raspi-config/init_resize.sh||' /boot/cmdline.txt
    
    # note that the init.d/ script appears to have gone, and the resize itself
    # is now done inside the "fake init" script in
    # /usr/lib/raspi-config/init_resize.sh.  so the resize2fs_once
    # thing doesn't exist (I think).  I'm too scared to remove this,
    # though, just in case.  (for example, the raspi-config
    # interactive utility used to offer a resize option, and if it
    # still does, I can't imagine they've duplicated the "expandfs"
    # code to be in both places.)
    
    echo "updaterc.d - disabling resize2fs_once"
    update-rc.d resize2fs_once remove  # probably fails, cos it wasn't there (try removing this line?)
    
    echo " And removing the resize script - just to be sure"
    rm -f /etc/init.d/resize2fs_once   # same as above - try removing it?

    footer "Disabling resize2fs in raspbian"
}

function minimize_power() {
    header "Minimizing power usage"
    if [ -n "$SOLO_POWERMODE" ] ; then
	echo "... SOLO_POWERMODE is set to $SOLO_POWERMODE (in solo.conf)"
	if [ "$SOLO_POWERMODE" = "normal" ] ; then
	    echo "minimize_power: nothing to do..."
	else
	    echo "... disabling tvservice to save power [/opt/vc/bin/tvservice off]"
	    /opt/vc/bin/tvservice -off
	fi
    else
	echo "... SOLO_POWERMODE not set in solo.conf so assuming minimum power..."
	echo "... disabling tvservice to save power [/opt/vc/bin/tvservice off]"
	/opt/vc/bin/tvservice -off
    fi
    footer "Minimizing power usage"
}

function add_user() {
    header "Adding users"
    echo "... adding user amon..."
    useradd -m amon -s /bin/bash
    echo "... setting password"
    echo "amon:amon" | chpasswd
    echo "... adding amon to groups"
    usermod -a -G adm,dialout,cdrom,kmem,sudo,audio,video,plugdev,games,users,netdev,input,gpio amon
    echo "... enabling password-less sudo"
    echo "amon ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers
    footer "Adding users"
}


function _really_set_timezone() {
    echo "... setting timezone to tz: \"$1\" "
    if [ -f /usr/share/zoneinfo/$1 ] ; then
	ln -fs /usr/share/zoneinfo/$1 /etc/localtime
	dpkg-reconfigure --frontend noninteractive tzdata
    else
	echo "Timezone not recognised: \"$1\""
    fi

}

function set_timezone() {
    header "Setting the timezone ..."
    if [ -n "$SOLO_TZ" ] ; then
	echo "... solo.conf wants timezone: SOLO_TZ=\"$SOLO_TZ\""
	if [ "$SOLO_TZ" != "SYS_TZ" ] ; then
	    _really_set_timezone $SOLO_TZ
	else
	    echo "... system timezone already matches SOLO_TZ, so doing nothing"
	fi
    else
	echo "... SOLO_TZ not set in solo.conf so setting timezone to Europe/London..."
	_really_set_timezone "Europe/London"
    fi
    cat /etc/timezone
    footer "Setting the timezone"
}


function setup_leds() {
    header "Setting up the leds"
    echo "... activating LEDs - led0[green] = heartbeat, led1[red] off"
    echo heartbeat > /sys/class/leds/led0/trigger # heartbeat on green LED
    echo none      > /sys/class/leds/led1/trigger # turn off the red LED
#    if is_pizero; then
#	echo "Detected we are on pizero, so inverting heartbeat on led0"
#	echo 1 > /sys/class/leds/led0/invert # this is active opposite on pi0.
#    fi
    footer "Setting up the leds"
}


# setup rtc late in the boot process.
function setup_rtc_udev() {
    header "Setting up the RTC clock to use udev and systemd"

    #echo "enabling ntp time sync"
    #timedatectl set-ntp 1  # turn this off 2017-08-20
    echo "doing nothing for rtc setup."
    
    #    echo "" >> /boot/config.txt
    #    echo "dtoverlay=i2c-rtc,mcp7941x" >> /boot/config.txt
    footer "Setting up the RTC (setup_rtc_udev())"
}   

# setup rtc late in the boot process. ### UNUSED
function setup_rtc_late() {
    header "Setting up the RTC clock (late in boot process)"

    modprobe i2c-dev

    i2cdetect -y 1
    
    echo mcp7941x 0x6f > /sys/class/i2c-dev/i2c-1/device/new_device
    
    ls -l /dev/rtc0

    hwclock --show

    hwclock --hctosys
}   

# this is the "proper" way, but rc?.d isn't run any longer, by the look of it...
function setup_rtc() { UNUSED
    header "Setting up the RTC clock"

    # try removing the script and disabling:
    rm /etc/init.d/hwclock.sh
    update-rc.d hwclock.sh remove
    
    # we got rid of fake-hwclock, so now enable hwclock at boot time:
    echo "... enabling early boot support for RTC..."
    echo "... copying over our version of hwclock.sh (with call to setup_rtc.sh)"
    cp -v /opt/solo/hwclock.sh /etc/init.d/hwclock.sh
    echo "... now running update-rc.d to enable good old hwclock.sh"

    # need to remove and reinstall - thats how update-rc.d works:
    update-rc.d hwclock.sh defaults

    echo "done enabling hwclock.sh by update-rc.d.  Is it there?"
    ls -l /etc/rc2.d/S??hwclock.sh

    echo "and all the instances (find):"
    find /etc/rc?.d | grep hwclock
    
    footer "Setting up the RTC clock"
}
