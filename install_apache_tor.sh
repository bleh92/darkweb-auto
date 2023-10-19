#!/bin/bash

# Check if the user has root privileges
if [ "$EUID" -ne 0 ]; then
  echo "Please run this script with administrative privileges (e.g., using sudo)."
  exit 1
fi

# Prompt the user for the service name
read -p "Enter the name of your service: " service_name

# Update the package repository and install Apache
apt update   # For Debian/Ubuntu
# yum update   # For CentOS
apt install apache2   # For Debian/Ubuntu
# yum install httpd   # For CentOS

# Enable Apache modules for SSL and headers
a2enmod ssl
a2enmod headers

# Create a self-signed SSL certificate for HTTPS
openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout /etc/ssl/private/apache-selfsigned.key -out /etc/ssl/certs/apache-selfsigned.crt

# Configure Apache to listen on ports 80 and 443
cat <<EOL > /etc/apache2/sites-available/$service_name.conf
<VirtualHost *:80>
    ServerAdmin webmaster@localhost
    DocumentRoot /var/www/html

    <Directory /var/www/html>
        Options Indexes FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>

    ErrorLog \${APACHE_LOG_DIR}/error.log
    CustomLog \${APACHE_LOG_DIR}/access.log combined
</VirtualHost>

<IfModule mod_ssl.c>
<VirtualHost *:443>
    ServerAdmin webmaster@localhost
    DocumentRoot /var/www/html

    <Directory /var/www/html>
        Options Indexes FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>

    ErrorLog \${APACHE_LOG_DIR}/error.log
    CustomLog \${APACHE_LOG_DIR}/access.log combined

    SSLEngine on
    SSLCertificateFile /etc/ssl/certs/apache-selfsigned.crt
    SSLCertificateKeyFile /etc/ssl/private/apache-selfsigned.key
</VirtualHost>
</IfModule>
EOL

# Enable the virtual host
a2ensite $service_name

# Disable the default Apache site
a2dissite 000-default

# Reload Apache to apply the changes
systemctl reload apache2   # For Debian/Ubuntu
# systemctl restart httpd   # For CentOS

# Start Apache service
systemctl start apache2   # For Debian/Ubuntu
# systemctl start httpd   # For CentOS

# Ensure Apache starts on boot
systemctl enable apache2   # For Debian/Ubuntu
# systemctl enable httpd   # For CentOS

# Install Tor
apt install tor   # For Debian/Ubuntu
# yum install tor   # For CentOS

# Configure Tor to host a .onion service for your web server
cat <<EOL > /etc/tor/torrc
HiddenServiceDir /var/lib/tor/hidden_service/
HiddenServicePort 80 127.0.0.1:80
HiddenServicePort 443 127.0.0.1:443
EOL

# Start the Tor service
systemctl start tor   # For Debian/Ubuntu
# systemctl start tor   # For CentOS

# Ensure Tor starts on boot
systemctl enable tor   # For Debian/Ubuntu
# systemctl enable tor   # For CentOS

echo "Apache has been installed and configured to run the $service_name service on 127.0.0.1 ports 80 and 443, and a .onion service has been set up."
