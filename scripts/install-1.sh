#!/bin/bash
sudo yum update -y
sudo yum install -y httpd24 php56 php56-mysqlnd mysql
sudo groupadd www
sudo usermod -a -G www ec2-user
sudo chown -R root:www /var/www
sudo chmod 2775 /var/www
wget https://wordpress.org/latest.tar.gz
curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
tar -xzf latest.tar.gz
cd wordpress/
cp wp-config-sample.php wp-config.php
sudo usermod -a -G www apache
sudo chown -R apache /var/www
sudo chgrp -R www /var/www
sudo mv * /var/www/html/
sudo usermod -a -G www apache
sudo chown -R apache /var/www
sudo chgrp -R www /var/www
sudo chmod 2775 /var/www
find /var/www -type d -exec sudo chmod 2775 {} \;
find /var/www -type f -exec sudo chmod 0664 {} \;
sudo service httpd start
sudo chkconfig httpd on
echo "script deployed"
