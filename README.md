### Introduction

This repository contains scripts and configuration files needed to obtain a working instance of NextCloud on encrypted disks based on the official NextCloud Docker image and LUKS technology.

The following procedure has been tested on a Debian 9 (Stretch) virtual machine with two exernal devices:
- `/dev/vda` used for the DBMS working directory (mounted on `/opt/nextcloud/db`)
- `/dev/vdb` used to store NextCloud data (mounted on `/opt/nextcloud/db`)

N.B. **the devices must not be partitioned, formatted and mounted**. the LUKS script will take care of encrypting, formatting and mounting them on the correct locations

### Procedure

The procedure assumes as working directory the one containing the repo.
Start by updating packages:
```
apt update
apt -y full-upgrade
apt -y autoremove
```

Then install Docker and the required packages:
```
apt -y install apt-transport-https ca-certificates curl gnupg2 software-properties-common
curl -fsSL https://download.docker.com/linux/debian/gpg | sudo apt-key add -
add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/debian $(lsb_release -cs) stable"
apt update
apt -y install docker-ce
```

Install docker-compose (choose the last available version on https://github.com/docker/compose/releases)
```
curl -s https://github.com/docker/compose/releases | grep compose/releases | grep uname | head -1 | sed s/\<pre\>\<code\>// | bash
chmod +x /usr/local/bin/docker-compose
```

Encrypt devices with the scripts from https://github.com/mtangaro/fast-luks (copied in this repo and adapted; `/dev/vda` is the DB device, `/dev/vdb` is the NextCloud data device):
```
apt -y install cryptsetup # you will be asked to choose your keyboard layout
cp luksctl_d* /usr/local/bin/
cp fast_luks_d* /usr/local/bin/
mkdir -p /etc/luks
mkdir -p /opt/nextcloud/db
mkdir -p /opt/nextcloud/data
fast_luks_db # insert password for the encryption of the device where DB files are stored
fast_luks_data # insert password for the encryption of the device where NextCloud data files are stored
rm -r /opt/nextcloud/data/lost+found/
rm -r /opt/nextcloud/db/lost+found/
```

N.B. **the password is not stored anywhere and cannot be recovered or reset. If forgotten, when unmounting the devices all data will be lost**. Please store it in a safe place.

Substitute the following fields in the `docker-compose.yml` file:
- `<MYSQL_ROOT_PASSWORD>` --> the root password for MySQL
- `<MYSQL_nextcloud_USER_PASSWORD>` --> the password for the MySQL `nextcloud` user.

and start the containers:
```
cp docker-compose.yml /opt/nextcloud/
cd /opt/nextcloud
docker-compose up -d
```

This will start two containers, one called `nextcloud_app_1`, the app, and another called `nextcloud_db_1`, the DBMS. The DB container is linked to the app one, which can refer to it as `db` (as will be specified in the online configuration).
Complete the configuration online, pointing your browser to `http://<DNS_NAME>:8080` and filling in the fields using the following parameter:
- In the field "Create an admin account" write username and password you want to use the administrator account
- Click on the drop down menu "Storage & database"
  - In the field "Data folder" put `/var/www/html/data` (there should already be the right path)
  - In the field "Configure the database" choose MySQL/MariaDB and put the following parameters
    - Database user --> `nextcloud`
    - Database password --> the value of the key `MYSQL_PASSWORD` in the `docker-compose.yml` file
    - Database name --> `nextcloud`
    - Database host --> `db:3306`

then click on "Finish setup"


### Reverse proxy configuration
Now the app is available at the 8080 port, on HTTP without SSL. To enable SSL:
```
apt -y install nginx
rm /etc/nginx/sites-available/* /etc/nginx/sites-enabled/*
cp nextcloud.nginx /etc/nginx/sites-available/nextcloud
```
Substitute `the <DNS_NAME>` string in the `/etc/nginx/sites-available/nextcloud` file with the DNS name associated to your public IP.
Create the directory to store the certificate and the private key:
```
mkdir -p /etc/nginx/ssl/
```
Link the SSL certificate to `/etc/nginx/ssl/nextcloud.crt` and the private key to `/etc/nginx/ssl/nextcloud.key`
```
ln -s <PATH_TO_SSL_CERTIFICATE> /etc/nginx/ssl/nextcloud.crt
ln -s <PATH_TO_PRIVATE_KEY> /etc/nginx/ssl/nextcloud.key
```
Activate the proxy:
```
ln -s /etc/nginx/sites-available/nextcloud /etc/nginx/sites-enabled/nextcloud
systemctl restart nginx.service
```

Now the app is available on `https://<DNS_NAME>` (with http to https redirection).

### Enable the mail service
Enter the app container:
```
docker exec -it nextcloud_app_1 bash
```
and install sendmail
```
apt update
apt -y install sendmail
```
