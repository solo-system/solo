##  moved this here out of provision.sh, because it's complicated
## and I am about to rewrite the whole thing for more up-to-date clac software.


# OK - I just wrote the below code to install the CLAC support:
# comments:
# 1) it's a real mess having to pick these bits from idfferent places
# 2) Most of this ought to be part of the "amon" package (or atleast
# in the amon directory).

# if [ $RJCLAC = "yes" ] ; then
if true ; then
    echo 
    echo "Installing Ragnar Jensen's CLAC stuff..."

    mkdir /opt/solo/rj/
    pushd /opt/solo/rj/

    # Step 1 : get the debs and unpack.
    # They live here: 
    # Normal : https://drive.google.com/uc?export=download&id=0BzIaxMH3N5O1OGNpYl8wRVhqbU0
    # Raspiv2: https://drive.google.com/uc?export=download&id=0BzIaxMH3N5O1S1JyTkJ4Z090cHc
    # but I've kept a local copy in:
    echo "... fetching CLAC debs"
    wget jdmc2.com/rjdebs/linux-image-3.18.9cludlmmapfll_3.18.9cludlmmapfll-3_armhf.deb
    wget jdmc2.com/rjdebs/linux-image-3.18.9-v7cludlmmapfll_3.18.9-v7cludlmmapfll-4_armhf.deb
    # They should be md5sum: 
    # b7947af7cbeb34d2d0324c6896aedf67  linux-image-3.18.9cludlmmapfll_3.18.9cludlmmapfll-3_armhf.deb
    # b168d2d736974f1f681fdefa9e246909  linux-image-3.18.9-v7cludlmmapfll_3.18.9-v7cludlmmapfll-4_armhf.deb

    echo "... installing debs"
    dpkg -i linux-image-3.18.9-v7cludlmmapfll_3.18.9-v7cludlmmapfll-4_armhf.deb
    dpkg -i linux-image-3.18.9cludlmmapfll_3.18.9cludlmmapfll-3_armhf.deb

    # RJ's kernels are now installed as 
    # /boot/vmlinuz-3.18.9cludlmmapfll
    # /boot/vmlinuz-3.18.9-v7cludlmmapfll

    # we rename them to kernel.img and kernel7.img so that the
    # bootstrap code finds them (and chooses magically between them
    # (it knows - somehow).  We previously put a kernel= line into the
    # /boot/config.txt, but that can't cater for the pi/pi2
    # distinction. 

    # NOTE: I worried that all the other things (system.map, initrd,
    # /lib/modules etc) would not now be found because the kernel's
    # filename no longer matches it's version, but this is not what's
    # required.  Once booted a kernel looks for these things according
    # to it's uname -r, not it's filename.

    # TODO: could save space removing /lib/modules/{3.18.11+,3.18.11-v7+}

    echo "... Copying new CLAC kernels into place..."
    mv -v /boot/vmlinuz-3.18.9cludlmmapfll /boot/kernel.img
    mv -v /boot/vmlinuz-3.18.9-v7cludlmmapfll /boot/kernel7.img

    # get the older tarball, containing the DTS and the control scripts:
    wget jdmc2.com/rjdebs/kernel_3_18_9_W_CL.tgz # older versino of it all (debs superscede, but don't have dts.)
    tar xfz kernel_3_18_9_W_CL.tgz 
    echo "... installing clac overlay to /boot/"
    cp -v boot/overlays/rpi-cirrus-wm5102-overlay.dtb /boot/overlays/
    echo "... installing use_case scripts to /home/amon/clac..."
    cp -prv  home/pi/use_case_scripts /home/amon/clac/
    chmod +x /home/amon/clac/*.sh
    
    popd # done fiddling with the debs and tarfile.  Could delete them here (TODO: PURGE)
    echo "... Done installing debs, dtoverlay and control-scripts"

    echo "... Updating /boot/config.txt"
    cp /boot/config.txt /boot/config.txt.pre-provision
    echo "" >> /boot/config.txt # add a new line
    echo "# Below added by solo's provision.sh" >> /boot/config.txt
    # echo "kernel=vmlinuz-3.18.9cludlmmapfll" >> /boot/config.txt
    # echo "kernel=vmlinuz-3.18.9-v7cludlmmapfll" >> /boot/config.txt
    echo "dtparam=spi=on" >> /boot/config.txt
    echo "dtoverlay=rpi-cirrus-wm5102-overlay" >> /boot/config.txt
    echo "... done updating /boot/config.txt"

    # now add stuff to blacklist
    echo "... updating blacklist with dependencies"
    bl=/etc/modprobe.d/raspi-blacklist.conf
    echo "... updating $bl"
    #cp $bl $bl.pre-provision # no old version to backup.
    echo "# lines below added by solo's provision.sh" >> $bl
    echo "softdep arizona-spi pre: arizona-ldo1" >> $bl
    echo "softdep spi-bcm2708 pre: fixed" >> $bl
    echo "... done updating blacklist with dependencies"

    echo "Done Installing CLAC stuff..."
fi
