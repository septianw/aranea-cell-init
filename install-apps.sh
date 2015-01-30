#!/bin/bash

# adminuname="jurukunci"
# adminemail="cs@aranea.ws"
#
# dbhost="192.168.122.10"
# dbuser="wp01"
# dbpass="Activat3d."

if [ -z $1 ]
then
  echo "usage init.sh /path/to/config"
  exit 1
else
  . $1
fi

get() {
  file=$1
  fin=$2
  delim=$3
  cat $file | grep $fin | tail -n1 | tr -d [:space:] | cut -d$delim -f2
}

apt-get -y update
apt-get -y install mariadb-client wget git-core pwgen lshell python-pip;

wget -qO ee rt.cx/ee && sudo bash ee;
ee stack install nginx && ee stack install php && ee stack install wpcli;

uname=$(get /var/log/easyengine/ee.log "username" ":");
upass=$(get /var/log/easyengine/ee.log "password" ":");
echo "nginx username:"$uname >> credential.txt
echo "nginx password:"$upass >> credential.txt

ip=$(ifconfig  | grep 'inet addr:'| grep -v '127.0.0.1' | cut -d: -f2 | awk '{ print $1}')
sed -i -e "s/ip-address =/ip-address = $ip/g" /etc/easyengine/ee.conf
sed -i -e "s/grant-host = localhost/grant-host = $ip/g" /etc/easyengine/ee.conf
sed -i -e "s/user =/user = $adminuname/g" /etc/easyengine/ee.conf
sed -i -e "s/db-user = $adminuname false/db-user = false/g" /etc/easyengine/ee.conf
sed -i -e "s/email =/email = $adminemail/g" /etc/easyengine/ee.conf

sudo useradd -s /bin/bash -m -d /home/wpee -U wpee;
wget https://raw.githubusercontent.com/septianw/aranea-cell-init/master/create-site.sh
mv create-site.sh /usr/local/sbin/create-site
chmod 750 /usr/local/sbin/create-site
# echo "Cmnd_Alias USERS  = /usr/sbin/useradd,/usr/sbin/userdel,/usr/sbin/usermod,/usr/bin/users" >> /etc/sudoers
# echo "Cmnd_Alias CH     = /bin/chown,/bin/chmod" >> /etc/sudoers
# echo "Cmnd_Alias DISK   = /bin/dd,/bin/mount,/bin/mkdir,/sbin/losetup,/sbin/mkfs.ext4,/bin/umount,/usr/bin/tee" >> /etc/sudoers
# echo "Cmnd_Alias USM    = USERS,CH,DISK" >> /etc/sudoers
echo "wpee    wp=(root)NOPASSWD:/usr/local/sbin/ee,/usr/local/sbin/create-site" >> /etc/sudoers

echo '[client]' > /home/wpee/.my.cnf
echo "host=$dbhost" >> /home/wpee/.my.cnf
echo "user=$dbuser" >> /home/wpee/.my.cnf
echo "password=$dbpass" >> /home/wpee/.my.cnf
cp /home/wpee/.my.cnf /root/.my.cnf
chown wpee:wpee /home/wpee/.my.cnf

mkdir -p /disks
chown -Rf wpee:wpee /disks
