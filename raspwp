#!/bin/bash

# Prompt for user input
read -p "Enter your domain name (e.g., example.com): " DOMAIN
read -p "Enter your MySQL database name: " DB_NAME
read -p "Enter your MySQL username: " DB_USER
read -s -p "Enter your MySQL password: " DB_PASS
echo
read -p "Enter the folder name to install WordPress (e.g., wordpress): " WP_FOLDER
read -p "Enter your Cloudflare token: " CF_TOKEN

# Define the full path for WordPress installation
WP_PATH="/var/www/$WP_FOLDER"

# Update and upgrade the system
sudo apt update && sudo apt upgrade -y

# Install necessary packages
sudo apt install -y wget curl gnupg2 ca-certificates lsb-release apt-transport-https

# Install Nginx
sudo apt install -y nginx

# Install MariaDB
sudo apt install -y mariadb-server mariadb-client

# Secure MariaDB installation
sudo mysql_secure_installation

# Install PHP and necessary extensions
sudo apt install -y php-fpm php-mysql php-cli php-curl php-gd php-mbstring php-xml php-xmlrpc php-soap php-intl php-zip

# Install phpMyAdmin
sudo apt install -y phpmyadmin

# Configure Nginx
sudo tee /etc/nginx/sites-available/wordpress <<EOF
server {
    listen 80;
    server_name $DOMAIN;

    root $WP_PATH;
    index index.php index.html index.htm;

    location / {
        try_files \$uri \$uri/ /index.php?\$args;
    }

    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/run/php/php7.3-fpm.sock;
    }

    location ~ /\.ht {
        deny all;
    }
}
EOF

# Enable the WordPress Nginx configuration
sudo ln -s /etc/nginx/sites-available/wordpress /etc/nginx/sites-enabled/
sudo unlink /etc/nginx/sites-enabled/default

# Download and extract WordPress
wget https://wordpress.org/latest.tar.gz
tar -xzvf latest.tar.gz
sudo mv wordpress $WP_PATH
sudo chown -R www-data:www-data $WP_PATH

# Restart Nginx
sudo systemctl restart nginx

# Set up MariaDB for WordPress
sudo mysql -u root -p <<EOF
CREATE DATABASE $DB_NAME DEFAULT CHARACTER SET utf8 COLLATE utf8_unicode_ci;
CREATE USER '$DB_USER'@'localhost' IDENTIFIED BY '$DB_PASS';
GRANT ALL PRIVILEGES ON $DB_NAME.* TO '$DB_USER'@'localhost';
FLUSH PRIVILEGES;
EXIT;
EOF

# Configure WordPress
sudo cp $WP_PATH/wp-config-sample.php $WP_PATH/wp-config.php
sudo sed -i "s/database_name_here/$DB_NAME/" $WP_PATH/wp-config.php
sudo sed -i "s/username_here/$DB_USER/" $WP_PATH/wp-config.php
sudo sed -i "s/password_here/$DB_PASS/" $WP_PATH/wp-config.php

# Install Cloudflare Zero Trust Tunnel (cloudflared)
wget https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-arm
sudo mv cloudflared-linux-arm /usr/local/bin/cloudflared
sudo chmod +x /usr/local/bin/cloudflared

# Configure and run Cloudflare Tunnel using the provided token
sudo cloudflared service install $CF_TOKEN

echo "Installation completed. Please visit http://$DOMAIN to finish setting up WordPress."
