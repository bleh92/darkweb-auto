#!/bin/bash

# Check if the user has root privileges
if [ "$EUID" -ne 0 ]; then
  echo "Please run this script with administrative privileges (e.g., using sudo)."
  exit 1
fi

# Stop and disable Apache service
systemctl stop apache2   # For Debian/Ubuntu
# systemctl stop httpd   # For CentOS
systemctl disable apache2   # For Debian/Ubuntu
# systemctl disable httpd   # For CentOS

# Remove Apache packages and configuration files
apt purge apache2*   # For Debian/Ubuntu
# yum remove httpd*   # For CentOS
apt autoremove   # For Debian/Ubuntu (removes unused packages)
# yum autoremove   # For CentOS

# Delete Apache configuration files and data
rm -rf /etc/apache2
# rm -rf /etc/httpd   # For CentOS
rm -rf /var/www/html

# Stop and disable Tor service
systemctl stop tor   # For Debian/Ubuntu
# systemctl stop tor   # For CentOS
systemctl disable tor   # For Debian/Ubuntu
# systemctl disable tor   # For CentOS

# Remove Tor package
apt purge tor   # For Debian/Ubuntu
# yum remove tor   # For CentOS

# Delete Tor configuration files and data
rm -rf /etc/tor
rm -rf /var/lib/tor

echo "Apache and Tor have been uninstalled and purged."
