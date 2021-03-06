#!/bin/bash

if [ -z $1 ]
then
  echo "usage: create-site <sitename> <size of disk>"
  exit 2
fi

if [ -z $2 ]
then
  echo "usage: create-site <sitename> <size of disk>"
  exit 2
fi

sitename=$1
size=$2

function parse_yaml {
   local prefix=$2
   local s='[[:space:]]*' w='[a-zA-Z0-9_]*' fs=$(echo @|tr @ '\034')
   sed -ne "s|^\($s\):|\1|" \
        -e "s|^\($s\)\($w\)$s:$s[\"']\(.*\)[\"']$s\$|\1$fs\2$fs\3|p" \
        -e "s|^\($s\)\($w\)$s:$s\(.*\)$s\$|\1$fs\2$fs\3|p"  $1 |
   awk -F$fs '{
      indent = length($1)/2;
      vname[indent] = $2;
      for (i in vname) {if (i > indent) {delete vname[i]}}
      if (length($3) > 0) {
         vn=""; for (i=0; i<indent; i++) {vn=(vn)(vname[i])("_")}
         printf("%s%s%s=\"%s\"\n", "'$prefix'",vn, $2, $3);
      }
   }'
}


echo "Creating site"
sudo ee site create $sitename --wpsc > $sitename.log

echo "fetching info"
sudo ee site info $sitename | tr [:blank:] "|" | tr -s "|" | tail -n7 | sed -r "s/\x1B\[([0-9]{1,3}((;[0-9]{1,3})*)?)?[m|K]//g" > $sitename.info
webroot=$(sudo ee site show $sitename | grep root | tr -d "\t" | tr " " "|" | tr -d ";" | cut -d"|" -f2)

echo "Deploying disk"
imgloc="/disks/"
dd if=/dev/zero of=$imgloc$sitename.img bs=4096 count=$[((1024*1024*1024)/4096)*size]
dev=$(sudo losetup -f)
sudo losetup $dev $imgloc$sitename.img
sudo mkfs.ext4 $dev
sudo losetup -d $dev
disk=$imgloc$sitename.img
echo $disk" deployed"

echo "creating user for sftp"
username=$(echo $sitename | tr "." "_")
password=$(pwgen -1cnsBv 16 1)
sudo useradd -s /bin/bash -d /home/$username -p $password -U -G www-data $username
echo "username = $username" >> sftp_user.info
echo "password = $password" >> sftp_user.info
echo "user created"

echo "mounting disk"
sudo mkdir /home/$username
sudo mount $disk /home/$username
echo "$disk       /home/$username       ext4    defaults    0   2" >> /etc/fstab
sudo chmod 700 /home/$username
sudo chown $username:$username /home/$username
echo "user mounted"

mkdir /home/$username/www-data
uploc=$(echo $webroot/wp-content/uploads/* | sed -r "s/\x1B\[([0-9]{1,3}((;[0-9]{1,3})*)?)?[m|K]//g")
sudo cp -Rf $uploc /home/$username/www-data
sudo chown -Rf www-data:www-data /home/$username/www-data
sudo mount --bind /home/$username/www-data $webroot/wp-content/uploads/
sudo chown www-data:www-data /home/$username/www-data
sudo chmod 750 /home/$username/www-data
echo "/home/$username       $webroot/wp-content/uploads/       none    bind    0   2" >> /etc/fstab
echo "web mounted"

mv $sitename.log /home/$username/
mv $sitename.info /home/$username/
mv sftp_user.info /home/$username/
