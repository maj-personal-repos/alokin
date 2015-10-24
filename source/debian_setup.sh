#!/bin/bash

apt-get update && apt-get upgrade
apt-get install vim aptitude
apt-get install ssh
apt-get install locales
sed -i '/en_US.UTF-8/s/^#//' /etc/locale.gen
locale-gen en_US.UTF-8
echo "changing root password"
passwd
update-rc.d galileod.sh defaults
echo "adding user galileo"
adduser galileo
