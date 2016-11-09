#!/bin/bash
sudo cd ~
sudo chmod +x wp-cli.phar
sudo mv wp-cli.phar /usr/local/bin/wp
sudo chmod +x /usr/local/bin/wp
cd /var/www/html
sudo echo "define( 'AWS_USE_EC2_IAM_ROLE', true);" >> /var/www/html/wp-config.php
sudo echo "define('DISALLOW_FILE_MODS', true);" >> /var/www/html/wp-config.php
sudo echo "define('WP_AUTO_UPDATE_CORE', false);" >> /var/www/html/wp-config.php
sudo service httpd restart
echo "script II deployed"
