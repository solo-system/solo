
### INTERACTIVE do do early.
sudo raspi-config
# dpkg-reconfigure tzdata # raspi-config handles this.
# hostname recorder

### get 2 files from jdmc2.com
echo 
echo "getting firstboot.sh, switchoff.py and rc.local.recorder ..."
scp -pr jdmc2@jdmc2.com:recorder/"{firstboot.sh,switchoff.py,rc.local.recorder}" /root/
chmod +x /root/firstboot.sh /root/switchoff.py /root/rc.local.recorder

### add commands to /etc/rc.local to run at normal boot times.
#sed -i 's:^exit 0$:/root/firstboot.sh >> /root/firstboot.log 2>\&1 || true\n&:' /etc/rc.local
#sed -i 's:^exit 0$:echo ds1307 0x68 > /sys/class/i2c-adapter/i2c-1/new_device >>/root/i2c.out\n&:' /etc/rc.local
#sed -i 's:^exit 0$:echo ds1307 0x68 > /sys/class/i2c-adapter/i2c-0/new_device >>/root/i2c.out \n&:' /etc/rc.local
#sed -i 's:^exit 0$:/root/switchoff.py \&\n&:' /etc/rc.local
#sed -i 's:^exit 0$:/opt/vc/bin/tvservice -off\n&:' /etc/rc.local
#sed -i 's:^exit 0$:amixer -q -c 1 set "Mic" 15dB\n&:' /etc/rc.local
#sed -i 's:^exit 0$:/sbin/hwclock -s || true\n&:' /etc/rc.local

sed -i 's:^exit 0$:\n/root/rc.local.recorder\n\n&:' /etc/rc.local

### Users:
adduser amon
usermod -a -G adm,dialout,cdrom,kmem,sudo,audio,video,plugdev,games,users,netdev,input,gpio amon

### install amon: (must happen after user amon is added)
echo "Downloading and Installing amon..."
scp -pr jdmc2@jdmc2.com:code/amon/ /home/amon
chown -R amon.amon /home/amon
echo "PATH=$PATH:/home/amon/amon/" > /home/amon/.bashrc

#### Packages:
#apt-get update
apt-get -y purge fake-hwclock # wolfram-engine put it back
#apt-get -y upgrade
apt-get install i2c-tools bootlogd
#rpi-update

#### hw clock:
# backup the hwclock.sh script
# cp /etc/init.d/hwclock.sh /etc/init.d/hwclock.sh.orig
# first, add the line that enables the rtc on the i2c bus.
# sed -i '0,/case/{s:    case: PUT THE ECHO HERE   \n\n    case:}'  /etc/init.d/hwclock.sh
# service hwclock.sh requires rtc which neds i2c which is a module loaded by kmod
# so change the "requirements" of hwclock.sh to require kmod:
# sed -i 's/^# Required-Start:    /&kmod /' /etc/init.d/hwclock.sh
# DAmn - this generates a loop :
# insserv: There is a loop between service hwclock and kmod if started
# insserv:  loop involving service kmod at depth 5
# insserv:  loop involving service checkroot at depth 4
# insserv:  loop involving service hwclock at depth 7
# insserv: There is a loop between service hwclock and kmod if started
# insserv: There is a loop between service kmod and checkroot if started
# insserv:  loop involving service urandom at depth 14
# insserv:  loop involving service checkroot-bootclean at depth 18
# insserv:  loop involving service mtab at depth 18


# now add this new startup service to the init system...
update-rc.d hwclock.sh defaults
update-rc.d hwclock.sh enable

# add the modules we need to /etc/modules:
echo "i2c-dev" >> /etc/modules
echo "i2c-bcm2708" >> /etc/modules



#echo
#echo "HELP - THIS NEEDS TO MOVE to firstboot, since it depends on the hw platform I think"
#echo "HELP - please add this line just before the case .. start) stanza"
#echo "echo ds1307 0x68 > /sys/class/i2c-adapter/i2c-*/new_device"
#echo "press return to launch editor......"
#read
#nano /etc/init.d/hwclock.sh

#echo "Now adding watchdog to amon's crontab:"
#echo "* * * * *       /home/amon/amon/amon watchdog >> /home/amon/amon/cron.log 2>&1" | crontab -u amon -

#echo "need to add nightly reboot to root's crontab"
#echo "59 23 * * * /sbin/reboot" | crontab - 


echo "Tidying up misc files..."
#### do lots of tidy up here.
rm -f /home/amon/pistore.desktop
# rm -rf /tmp/??? /var/log?

sync
sync

echo "Finished turning this into a bootable \"recorder\" image"
echo "Do any hand checking you like, then enable the cronjob and:"
echo "type shutdown now"
echo "then copy this card onto the PC (as an img) and then try booting with it to test"
echo "can use this very card to boot from, once it's backed up onto PC".

exit 0
