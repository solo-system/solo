#!/usr/bin/env python

import time, os
import RPi.GPIO as GPIO

POWERPIN = 11
GPIO.setmode(GPIO.BCM)
GPIO.setup(POWERPIN, GPIO.IN, pull_up_down = GPIO.PUD_UP)

print "Starting shutdown GPIO monitor"
while (GPIO.input(POWERPIN) == True):
#    print "pin is high - doing nothing."
    time.sleep(1)

print "switchoff.py: detected pin is high - so rebooting... "
os.system("echo mmc0 > /sys/class/leds/led0/trigger")
os.system("sudo shutdown -h now&")

while True:
  print "rebooting..."
