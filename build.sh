#!/bin/bash

# configuration
download_url="http://downloadmirror.intel.com/24355/eng/"
download_filename="SDCard.1.0.4.tar.bz2"
deb_mirror="http://http.debian.net/debian"
deb_release="wheezy"
buildenv="./build"
current_directory=`pwd`
source_directory=$current_directory/source
mydate=`date +%Y%m%d`
imagename="loopback_${deb_release}_${mydate}.img"
image=""
# gen1 or gen2
board="gen1"

# basic checks
if [ "$deb_local_mirror" == "" ]; then
  deb_local_mirror=$deb_mirror  
fi
if [ $EUID -ne 0 ]; then
  echo "this tool must be run as root"
  exit 1	
fi

# download and extract yocto build
cd /tmp
if [ ! -e $download_filename ]; then
  wget $download_url$download_filename
else
  echo "file has already been downloaded..."
fi
tar xvjf $download_filename
cd $current_directory

# create needed directories
mkdir -p $buildenv mnt-loop sdcard image

# cleanup previous builds
rm -rf $buildenv/* sdcard/*

# copy original system files
cp -r /tmp/image-full-galileo/* sdcard/

# create the image
echo "creating the blank image..."
mkdir -p $buildenv
image="${buildenv}/${imagename}"
dd if=/dev/zero of=$image bs=1G count=1
echo "image $image created"

# format the file system
mkfs.ext3 $image

# mount the bootstrap image
mount -o loop $image mnt-loop

# mount the original sys image
mount -o loop sdcard/image-full-galileo-clanton.ext3 image

# build the boostrap image
debootstrap --arch i386 wheezy ./mnt-loop $deb_mirror

# copy modules over
cp -r image/lib/modules mnt-loop/lib

# make needed dirs
cd mnt-loop
mkdir -p media sketch
mkdir -p opt/cln
cd media
mkdir card cf hdd mmc1 net ram realroot union
cd ../dev
mkdir mtdblock0 mtd0
cd ../..

# copy sys files over
cp -ru image/lib/ mnt-loop/
cp -ru image/usr/lib/libstdc++.so* mnt-loop/usr/lib
cp -ru image/lib/libc.so.0 mnt-loop/usr/lib
cp -ru image/lib/libm.so.0 mnt-loop/usr/lib
cp image/usr/bin/killall mnt-loop/usr/bin/
cp image/etc/inittab mnt-loop/etc/inittab
cp image/etc/modules-load.quark/galileo.conf mnt-loop/etc/modules
cp -r image/opt/ mnt-loop/
cp $source_directory/galileod-${board}.sh mnt-loop/etc/init.d/galileod.sh
chown root:root mnt-loop/etc/init.d/galileod.sh

# uncomment the following line to run getty on gadget serial. note: you must also comment out cp ./galileod line from above to avoid having the galileo scripts using the same serial port
#echo "2:2345:respawn:/sbin/getty 38400 ttyGS0 vt100" >> mnt-loop/etc/inittab

# setup debian image
echo "
auto eth0
iface eth0 inet dhcp
" >> mnt-loop/etc/network/interfaces
echo "Galileo" > mnt-loop/etc/hostname
mount -t proc proc mnt-loop/proc
mount -t sysfs sysfs mnt-loop/sys
cp $source_directory/debian_setup.sh mnt-loop/tmp/debian_setup.sh
chmod +x mnt-loop/tmp/debian_setup.sh
chroot mnt-loop /tmp/debian_setup.sh
rm mnt-loop/tmp/debian_setup.sh

# rollback ssh
cp $source_directory/ssh_rollback.sh mnt-loop/tmp/ssh_rollback.sh
chmod +x mnt-loop/tmp/ssh_rollback.sh
chroot mnt-loop /tmp/ssh_rollback.sh
rm mnt-loop/tmp/ssh_rollback.sh

# rollback git
cp $source_directory/git_rollback.sh mnt-loop/tmp/git_rollback.sh
chmod +x mnt-loop/tmp/git_rollback.sh
chroot mnt-loop /tmp/git_rollback.sh
rm mnt-loop/tmp/git_rollback.sh

# cleanup
umount image
umount mnt-loop/proc
umount mnt-loop/sys
umount mnt-loop
rm sdcard/image-full-galileo-clanton.ext3
cp $image sdcard/image-full-galileo-clanton.ext3
rm -rf image mnt-loop build

# reminder
echo "Don't forget to copy all the files from the sdcard folder to the sd card."

