#!/bin/bash

# Check if the user has root privileges
if [ "$EUID" -ne 0 ]; then
  echo "Please run this script with administrative privileges (e.g., using sudo)."
  exit 1
fi

# Update the package repository and install Apache
apt update
apt install -y apache2

# Edit /etc/apache2/ports.conf to listen on 127.0.0.1 for ports 80 and 443
if ! grep -q "Listen 127.0.0.1:80" /etc/apache2/ports.conf; then
  sed -i 's/Listen 0.0.0.0:80/Listen 127.0.0.1:80/' /etc/apache2/ports.conf
fi

if ! grep -q "Listen 127.0.0.1:443" /etc/apache2/ports.conf; then
  sed -i 's/Listen 0.0.0.0:443/Listen 127.0.0.1:443/' /etc/apache2/ports.conf
fi

# Enable Apache modules for SSL and headers
a2enmod ssl
a2enmod headers

# Create a self-signed SSL certificate for HTTPS
openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout /etc/ssl/private/apache-selfsigned.key -out /etc/ssl/certs/apache-selfsigned.crt -subj "/C=/ST=/L=/O=/OU=/CN=127.0.0.1"

# Start the Apache service
systemctl start apache2

# Install Tor if it's not already installed
if ! command -v tor &> /dev/null; then
  echo "Installing Tor..."
  apt update
  apt install -y tor
fi

# Open the Tor configuration file for editing
torrc="/etc/tor/torrc"
if ! [ -f "$torrc" ]; then
  echo "Tor configuration file not found: $torrc"
  exit 1
fi

# Uncomment the HiddenServiceDir and HiddenServicePort lines
sed -i 's/#HiddenServiceDir/HiddenServiceDir/' "$torrc"
sed -i 's/#HiddenServicePort/HiddenServicePort/' "$torrc"

# Save the Tor configuration file

# Restart Tor to apply the changes
systemctl restart tor

# Display the .onion address
onion_address_file="/var/lib/tor/hidden_service/hostname"
if [ -f "$onion_address_file" ]; then
  echo "Your Tor hidden service .onion address is:"
  cat "$onion_address_file"
else
  echo "Failed to find the .onion address. Check your Tor configuration."
fi
