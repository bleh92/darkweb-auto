#!/bin/bash

# Check if the script is run as root
if [ "$EUID" -ne 0 ]; then
  echo "Please run this script as root."
  exit 1
fi

# Prompt the user for the onion prefix
read -p "Please enter the prefix of the onion: " onion_prefix

# Prompt the user for the number of .onion addresses they need
read -p "Enter the number of .onion addresses you need: " onion_count

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
notice_log="/var/log/tor/notices.log"
info_log="/var/log/tor/info.log"
torrc="/etc/tor/torrc"

# Check if the torrc file exists
if [ -f "$torrc" ]; then
    # Append the log directives to the torrc file
    echo "Log notice file $notice_log" >> "$torrc"
    echo "Log info file $info_log" >> "$torrc"
    echo "Log notice syslog" >> "$torrc"  # Optionally, you can log to syslog as well
    echo "Log info syslog" >> "$torrc"    # Optionally, you can log to syslog as well
    echo "Log debug syslog" >> "$torrc"   # Optionally, you can log to syslog as well
    echo "Log debug file /var/log/tor/debug.log" >> "$torrc"  # Optionally, you can log to a debug file
    echo "Log debug file /var/log/tor/debug.log" >> "$torrc"  # Optionally, you can log to a debug file
    echo "Log debug file /var/log/tor/debug.log" >> "$torrc"  # Optionally, you can log to a debug file

    echo "Log debug file /var/log/tor/debug.log" >> "$torrc"  # Optionally, you can log to a debug file
else
    echo "Error: Tor configuration file $torrc not found."
    exit 1
fi

# Dynamically add HiddenServiceDir and HiddenServicePort lines based on the onion_count
for ((i = 0; i < onion_count; i++)); do
  hidden_service_dir="/var/lib/tor/hidden_service_$i"
  hidden_service_port="80 127.0.0.1:80"
  
  echo "HiddenServiceDir $hidden_service_dir" >> "$torrc"
  echo "HiddenServicePort $hidden_service_port" >> "$torrc"
done



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

# Generate the onion addresses using the provided prefix and user-specified count
for ((i = 0; i < onion_count; i++)); do
  ./mkp224o filter "$onion_prefix" -t 4 -v -n 1 -d ~/Extracts
  onion_address_file="/var/lib/tor/hidden_service_$i/hostname"
  if [ -f "$onion_address_file" ]; then
    echo "Your Tor hidden service .onion address for hidden_service_$i is:"
    cat "$onion_address_file"
  else
    echo "Failed to find the .onion address for hidden_service_$i. Check your Tor configuration."
  fi
done

# Print instructions for copying the contents to the Tor hidden service directories
GREEN='\033[0;32m'
NC='\033[0m' # No Color

echo -e "${GREEN}Go to ~/Extracts and choose the onion you like and go inside that directory. Copy the contents of that directory to /var/lib/tor/hidden_service.${NC}"

# Copy the contents of the first folder within ~/Extracts to the Tor hidden service directories
for ((i = 0; i < onion_count; i++)); do
  current_folder=$(find ~/Extracts -mindepth 1 -maxdepth 1 -type d | head -n $((i + 1)) | tail -n 1)
  if [ -n "$current_folder" ]; then
    mkdir "/var/lib/tor/hidden_service_$i/"
    cp -r "$current_folder"/* "/var/lib/tor/hidden_service_$i/"
    chown debian-tor:debian-tor "/var/lib/tor/hidden_service_$i/"*
    chmod 600 "/var/lib/tor/hidden_service_$i/"*
    echo "Copied contents from $current_folder to /var/lib/tor/hidden_service_$i/"
  else
    echo "No folders found within ~/Extracts for hidden_service_$i. Make sure to create a folder with the onion address content."
  fi
done

# Restart the Tor service
systemctl restart tor
if [ -f "$onion_address_file" ]; then
  echo "Your Tor hidden service .onion address for hidden_service_$i is:"
  cat "$onion_address_file"
else
  echo "Failed to find the .onion address. Check your Tor configuration."
fi
