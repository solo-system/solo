#!/usr/bin/env python

import time, os
import RPi.GPIO as GPIO

# how shall we address the pins?
GPIO.setmode(GPIO.BCM)

# the shutdown button:
POWERPIN = 11
GPIO.setup(POWERPIN, GPIO.IN, pull_up_down = GPIO.PUD_UP)

# the playback button
PLAYPIN = 25
GPIO.setup(PLAYPIN, GPIO.IN, pull_up_down = GPIO.PUD_UP)

print "Starting shutdown GPIO monitor"
while (GPIO.input(POWERPIN) == True):

    # check the playback pin
    if (GPIO.input(PLAYPIN) == False):
        print "detected press on playback pin"
        os.system("/home/amon/amon/playback.sh")

    time.sleep(1)

# if we fall through the above, the pin has been pushed!

print "switchoff.py: detected pin is high - so rebooting... "
os.system("echo mmc0 > /sys/class/leds/led0/trigger")
os.system("sudo shutdown -h now &")

while True:
  print "rebooting..."
  time.sleep(1)
