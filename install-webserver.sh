#!/bin/bash

sudo apt-get update -y
sudo apt-get install -y apache2 git mysql-client php5 php5-curl curl php5-mysql

git clone https://github.com/Mahak-Patil/Launch-Setup
git clone https://github.com/Mahak-Patil/Environment-Setup
git clone https://github.com/Mahak-Patil/Application-Setup 

sudo mv ./Environment-Setup/images /var/www/html/images
sudo mv ./Application-Setup/index.html /var/www/html

sudo mv ./Application-Setup/*.php /var/www/html
sudo mv ./Launch-Setup/*.css /var/www/html
sudo mv ./Launch-Setup/*.js /var/www/html

curl -sS https://getcomposer.org/installer | sudo php &> /tmp/getcomposer.txt

sudo php composer.phar require aws/aws-sdk-php &> /tmp/runcomposer.txt

sudo mv vendor /var/www/html &> /tmp/movevendor.txt

sudo php /var/www/html/setup.php &> /tmp/database-setup.txt
echo "Hello" > /tmp/hello.txt