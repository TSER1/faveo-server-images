# Installing Faveo Helpdesk Freelancer, paid and Enterprise on Ubuntu <!-- omit in toc -->


<img alt="Ubuntu" src="https://upload.wikimedia.org/wikipedia/commons/thumb/a/ab/Logo-ubuntu_cof-orange-hex.svg/120px-Logo-ubuntu_cof-orange-hex.svg.png" width="120" height="120" />

Faveo can run on [Ubuntu 18.04 (Bionic Beaver)](http://releases.ubuntu.com/18.04/).

-   [Prerequisites](#prerequisites)
-   [Installation steps](#installation-steps)
    -   [1. Upload Faveo](#1-upload-faveo)
    -   [2. Setup the database](#2-setup-the-database)
    -   [3. Configure Nginx webserver](#5-configure-apache-webserver)
    -   [4. Install Faveo](#3-gui-faveo-installer)
    -   [5. Configure cron job](#4-configure-cron-job)
    -   [6. Redis Installation](#redis-installation)
    -   [7. SSL Installation](#ssl-installation)
    -   [8. Final step](#final-step)


<a id="prerequisites" name="prerequisites"></a>
## Prerequisites

Faveo depends on the following:

-   **Nginx** 
-   **PHP 7.3+** with the following extensions: curl, dom, gd, json, mbstring, openssl, pdo_mysql, tokenizer, zip
-   **MySQL 5.7+** or **MariaDB 10.3+**

### a. LAMP Installation
Follow the [instructions here](https://github.com/teddysun/lamp)
If you follow this step, no need to install Apache, PHP, MySQL separetely as listed below

Login as root user by typing the command below

```sh
sudo su
```

### b. Update your package list

```sh
apt update
apt upgrade -y
```

### c. Nginx
Use the below steps to install and start Nginx

```sh
sudo apt install nginx
systemctl start nginx
systemctl enable nginx
```

### d. PHP 7.3+

First add this PPA repository:

```sh
sudo apt-get install -y software-properties-common
sudo add-apt-repository ppa:ondrej/php
```

Then install php 7.3 with these extensions:

```sh
sudo apt update
sudo apt install -y php7.3 php7.3-mysql \
    php7.3-cli php7.3-common php7.3-fpm php7.3-soap php7.3-gd \
    php7.3-json php7.3-opcache  php7.3-mbstring php7.3-zip \
    php7.3-bcmath php7.3-intl php7.3-xml php7.3-curl  \
    php7.3-imap php7.3-ldap php7.3-gmp 
```

After installing PHP 7.3, run the commands below to open PHP default config file for Nginx…

```sh
sudo nano /etc/php/7.3/fpm/php.ini
```

Then make the changes on the following lines below in the file and save. The value below are great settings to apply in your environments.

```
file_uploads = On
allow_url_fopen = On
short_open_tag = On
memory_limit = 256M
cgi.fix_pathinfo = 0
upload_max_filesize = 100M
max_execution_time = 360
date.timezone = America/Chicago
```

<b>Setting Up ionCube</b>
```sh
wget http://downloads3.ioncube.com/loader_downloads/ioncube_loaders_lin_x86-64.tar.gz 
tar xvfz ioncube_loaders_lin_x86-64.tar.gz 
php -i | grep extension_dir
```
Make the note of path and directory from the above command.

Copy ion cube loader to Directory. Replace your *yourpath* below with actual path that was shown in the last step

```sh
cp ioncube/ioncube_loader_lin_7.3.so /usr/lib/php/yourpath
sed -i '2 a zend_extension = "/usr/lib/php/yourpath/ioncube_loader_lin_7.3.so"' /etc/php/7.3/fpm/php.ini
sed -i '2 a zend_extension = "/usr/lib/php/yourpath/ioncube_loader_lin_7.3.so"' /etc/php/7.3/cli/php.ini
systemctl restart nginx
```

### e. Mysql

The official Faveo installation uses Mysql as the database system and **this is the only official system we support**. While Laravel technically supports PostgreSQL and SQLite, we can't guarantee that it will work fine with Faveo as we've never tested it. Feel free to read [Laravel's documentation](https://laravel.com/docs/database#configuration) on that topic if you feel adventurous.


Install Mysql 5.7. Note that this only installs the package, but does not setup Mysql. This is done later in the instructions:

```sh
sudo apt update
sudo apt install -y mysql-server
```

Secure your mysql installation. Set a Password for mysql by running the command below

```sh
mysql_secure_installation 
```

**phpMyAdmin(Optional):** Install phpMyAdmin. This is optional step. phpMyAdmin gives a GUI to access and work with Database

```sh
sudo apt install phpmyadmin
```

<a id="installation-steps" name="installation-steps"></a>
## Installation steps

Once the softwares above are installed:


<a id="1-upload-faveo" name="1-upload-faveo"></a>
### 1. Upload Faveo
Please download Faveo Helpdesk from [https://billing.faveohelpdesk.com](https://billing.faveohelpdesk.com) and upload it to below directory

```sh
/var/www/faveo
```

<a id="2-setup-the-database" name="2-setup-the-database"></a>
### 2. Setup the database

Log in with the root account to configure the database.

```sh
mysql -u root -p
```

Create a database called 'faveo'.

```sql
CREATE DATABASE faveo;
```

Create a user called 'faveo' and its password 'strongpassword'.

```sql
CREATE USER 'faveo'@'localhost' IDENTIFIED BY 'strongpassword';
```

We have to authorize the new user on the faveo db so that he is allowed to change the database.

```sql
GRANT ALL ON faveo.* TO 'faveo'@'localhost';
```

And finally we apply the changes and exit the database.

```sql
FLUSH PRIVILEGES;
exit
```

### 3. Configure Nginx webserver

#### a. Give proper permissions to the project directory by running:

```sh
chown -R www-data:www-data /var/www/faveo 
chmod -R 755 /var/www/faveo 
chmod -R 755 /var/www/faveo/storage 
chmod -R 755 /var/www/faveo/bootstrap 
```

#### b. Create a copy of Nginx default config file
Finally, configure Nginx site configuration file for Faveo. This file will control how users access Faveo content. Run the commands below to create a new configuration file called faveo

```
sudo nano /etc/nginx/sites-available/faveo
```
Then copy and paste the content below into the file and save it. Replace the highlighted line with your own domain name and directory root location.
```
server {
    listen 80;
    listen [::]:80;
    root /var/www/faveo/public;
    index  index.php index.html index.htm;
    server_name  example.com www.example.com;

     client_max_body_size 100M;

    location / {
        try_files $uri $uri/ /index.php?$query_string;       
    }

    location ~ \.php$ {
               include snippets/fastcgi-php.conf;
               fastcgi_pass unix:/var/run/php/php7.3-fpm.sock;
               fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
               include fastcgi_params;
    }
}
```
Save the file and exit.

#### c. Enable the Faveo and Rewrite Module
After configuring the VirtualHost above, enable it by running the commands below

```sh
sudo ln -s /etc/nginx/sites-available/faveo /etc/nginx/sites-enabled/
sudo systemctl restart nginx
```

<a id="3-gui-faveo-installer" name="3-gui-faveo-installer"></a>
### 4. Install Faveo

Now you can install Faveo via [GUI](https://support.faveohelpdesk.com/show/web-gui-installer) Wizard or [CLI](https://support.faveohelpdesk.com/show/cli-installer).

<a id="4-configure-cron-job" name="4-configure-cron-job"></a>
### 5. Configure cron job

Faveo requires some background processes to continuously run. 
Basically those crons are needed to receive emails
To do this, setup a cron that runs every minute that triggers the following command `php artisan schedule:run`.

Create a new `/etc/cron.d/faveo` file with:

```sh
echo "* * * * * www-data /usr/bin/php7.3 /var/www/faveo/artisan schedule:run 2>&1" | sudo tee /etc/cron.d/faveo
```

<a id="redis-installation" name="redis-installation"></a>
### 6. Redis Installation

Redis is an open-source (BSD licensed), in-memory data structure store, used as a database, cache and message broker.

This is an optional step and will improve system performance and is highly recommended.

[Redis installation documentation](/docs/installation/providers/enterprise/ubuntu-redis.md)

<a id="ssl-installation" name="ssl-installation"></a>
### 7. SSL Installation

Secure Sockets Layer (SSL) is a standard security technology for establishing an encrypted link between a server and a client. Let's Encrypt is a free, automated, and open certificate authority.

This is an optional step and will improve system security and is highly recommended.

[Let’s Encrypt SSL installation documentation](/docs/installation/providers/enterprise/ubuntu-nginx-ssl.md)

<a id="final-step" name="final-step"></a>
### 8. Final step

The final step is to have fun with your newly created instance, which should be up and running to `http://localhost`.
