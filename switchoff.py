#!/usr/bin/env python

import time, os
import RPi.GPIO as GPIO

POWERPIN = 11
GPIO.setmode(GPIO.BCM)
GPIO.setup(POWERPIN, GPIO.IN, pull_up_down = GPIO.PUD_UP)

print "Starting shutdown GPIO monitor"
while (GPIO.input(POWERPIN) == True):
    time.sleep(1)

# if we fall through the above, the pin has been pushed!

print "switchoff.py: detected pin is high - so rebooting... "
os.system("echo mmc0 > /sys/class/leds/led0/trigger")
os.system("sudo shutdown -h now &")

while True:
  print "rebooting..."
  time.sleep(1)
