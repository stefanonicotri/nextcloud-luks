#!/bin/bash

#check if it's debian

SERVER_IP=$(hostname -I)

apt update 
apt -y full-upgrade
apt -y autoremove
apt -y install pwgen git apt-transport-https ca-certificates curl gnupg2 software-properties-common
curl -fsSL https://download.docker.com/linux/debian/gpg | sudo apt-key add -
add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/debian $(lsb_release -cs) stable"
apt update
apt -y install docker-ce
curl -s https://github.com/docker/compose/releases | grep compose/releases | grep uname | head -1 | sed s/\<pre\>\<code\>// | bash
chmod +x /usr/local/bin/docker-compose
mkdir -p /opt/nextcloud/db
mkdir -p /opt/nextcloud/data

# apt -y install cryptsetup # you will be asked to choose your keyboard layout
# cp luksctl_d* /usr/local/bin/
# cp fast_luks_d* /usr/local/bin/
# mkdir -p /etc/luks
# fast_luks_db # insert password for the encryption of the device where DB files are stored
# fast_luks_data # insert password for the encryption of the device where NextCloud data files are stored
# rm -r /opt/nextcloud/data/*
# rm -r /opt/nextcloud/db/*

MYSQL_ROOT_PASSWORD=$(pwgen -s 12 -1)
MYSQL_PASSWORD=$(pwgen -s 12 -1)
NEXTCLOUD_ADMIN_PASSWORD=$(pwgen -s 12 -1)
NEXTCLOUD_TABLE_PREFIX=$(pwgen -s 5 -1)_

echo "MySQL root password: " $MYSQL_ROOT_PASSWORD >> credentials.txt
echo "nextcloud MySQL user password: " $MYSQL_PASSWORD >> credentials.txt
echo "NextCloud admin user password: " $NEXTCLOUD_ADMIN_PASSWORD >> credentials.txt

sed -i "s/<MYSQL_ROOT_PASSWORD>/$MYSQL_ROOT_PASSWORD/" docker-compose.yml
sed -i "s/<MYSQL_PASSWORD>/$MYSQL_PASSWORD/" docker-compose.yml
sed -i "s/<NEXTCLOUD_ADMIN_PASSWORD>/$NEXTCLOUD_ADMIN_PASSWORD/" docker-compose.yml
sed -i "s/<NEXTCLOUD_TABLE_PREFIX>/$NEXTCLOUD_TABLE_PREFIX/" docker-compose.yml

cp docker-compose.yml /opt/nextcloud/
cd /opt/nextcloud
docker-compose up -d
