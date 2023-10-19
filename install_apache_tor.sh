#!/bin/bash

# Check if the script is run as root
if [ "$EUID" -ne 0 ]; then
  echo "Please run this script as root."
  exit 1
fi

# Prompt the user for the onion prefix
read -p "Please enter the prefix of the onion: " onion_prefix

# Install and configure Apache
apt-get update
apt-get install -y apache2

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

# Install and configure Tor
apt-get install -y tor

# Open the Tor configuration file for editing
torrc="/etc/tor/torrc"
if ! [ -f "$torrc" ]; then
  echo "Tor configuration file not found: $torrc"
  exit 1
fi

# Uncomment the HiddenServiceDir and HiddenServicePort lines
sed -i 's/#HiddenServiceDir/HiddenServiceDir/' "$torrc"
sed -i 's/#HiddenServicePort/HiddenServicePort/' "$torrc"

# Restart Tor to apply the changes
systemctl restart tor

# Install mkp224o
apt-get install -y build-essential libssl-dev libsodium-dev autoconf git

# Clone mkp224o from the repository
git clone https://github.com/cathugger/mkp224o.git

# Build mkp224o
cd mkp224o
./autogen.sh
./configure
make

# Generate the onion address using the provided prefix
./mkp224o filter "$onion_prefix" -t 4 -v -n 4 -d ~/Extracts/

# Print instructions for copying the contents to the Tor hidden service directory
GREEN='\033[0;32m'
NC='\033[0m' # No Color

echo -e "${GREEN}Go to ~/Extracts and choose the onion you like and go inside that directory. Copy the contents of that directory to /var/lib/tor/hidden_service.${NC}"

# Copy the contents to the Tor hidden service directory
cp -r ~/Extracts/* /var/lib/tor/hidden_service/
chown debian-tor:debian-tor /var/lib/tor/hidden_service/*
chmod 600 /var/lib/tor/hidden_service/*

# Restart the Tor service
systemctl restart tor

# Provide the .onion address to the user
onion_address_file="/var/lib/tor/hidden_service/hostname"
if [ -f "$onion_address_file" ]; then
  echo "Your Tor hidden service .onion address is:"
  cat "$onion_address_file"
else
  echo "Failed to find the .onion address. Check your Tor configuration."
fi
