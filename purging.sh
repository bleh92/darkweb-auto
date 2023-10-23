#!/bin/bash

# Check if the script is run as root
if [ "$EUID" -ne 0 ]; then
  echo "Please run this script as root."
  exit 1
fi

# Stop and remove Tor
systemctl stop tor
apt-get remove --purge -y tor
rm -rf /var/log/tor /var/lib/tor

# Stop and remove Apache
systemctl stop apache2
apt-get remove --purge -y apache2
rm -rf /etc/apache2 /var/www/html

# Remove mkp224o and its dependencies
apt-get remove --purge -y build-essential libssl-dev libsodium-dev autoconf git
rm -rf mkp224o

# Clean up SSL certificate
rm -f /etc/ssl/private/apache-selfsigned.key /etc/ssl/certs/apache-selfsigned.crt

# Remove changes made to /etc/apache2/ports.conf
sed -i 's/Listen 127.0.0.1:80/Listen 0.0.0.0:80/' /etc/apache2/ports.conf
sed -i 's/Listen 127.0.0.1:443/Listen 0.0.0.0:443/' /etc/apache2/ports.conf

# Clean up Tor configuration
torrc="/etc/tor/torrc"
sed -i '/Log/d' "$torrc"
sed -i '/HiddenServiceDir/d' "$torrc"
sed -i '/HiddenServicePort/d' "$torrc"

# Remove hidden service directories
onion_count=$(grep -c 'HiddenServiceDir' "$torrc")
for i in $(seq 0 $onion_count); do
  rm -rf "/var/lib/tor/hidden_service_$i"
done

echo "Reverted changes made by the original script."
