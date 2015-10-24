#!/bin/bash

apt-get purge openssh*
groupadd -g 35 sshd
useradd -u 35 -g 35 -c sshd -d / sshd
apt-get update
apt-get install screen build-essential zlib1g-dev libssl-dev 
cd /root
wget http://www.mirrorservice.org/pub/OpenBSD/OpenSSH/portable/openssh-5.9p1.tar.gz
tar xvf openssh-5.9p1.tar.gz
cd openssh-5.9p1
./configure
make -j8
make -j8 install
echo "#!/bin/sh
case \"\$1\" in
  start)
    echo \"Starting script ssh \"
    /usr/local/sbin/sshd
    ;;
  stop)
    echo \"Stopping script ssh\"
    kill -9 \`pgrep sshd\`
    ;;
  *)
    echo \"Usage: /etc/init.d/ssh {start|stop}\"
    exit 1
    ;;
esac

exit 0" > /etc/init.d/ssh
chmod 755 /etc/init.d/ssh
update-rc.d ssh defaults
