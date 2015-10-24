#!/bin/bash

cd /root
apt-get install liblocale-msgfmt-perl gettext libcurl4-openssl-dev curl ntpdate unzip libexpat1-dev python
wget https://github.com/git/git/archive/v1.7.0.9.zip
unzip v*
cd git-*
make -j8 prefix=/usr/local all 
make -j8 prefix=/usr/local install
