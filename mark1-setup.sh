#!/usr/bin/env bash

sudo apt-get update
sudo apt-get install nano wget -y
bash -c 'echo "alias ll='ls -l" >> /home/pi/.bashrc'
sudo apt-get install apt-transport-https -y
sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys F3B1AA8B
sudo bash -c 'echo "deb http://repo.mycroft.ai/repos/apt/debian debian main" > /etc/apt/sources.list.d/repo.mycroft.ai.list'
sudo apt-get update
# mycroft-python package has a dependency to libgdbm3 which is no longer distributed in current Raspbian OS (Buster)
wget http://ftp.debian.org/debian/pool/main/g/gdbm/libgdbm3_1.8.3-14_armhf.deb
sudo dpkg -i libgdbm3_1.8.3-14_armhf.deb
sudo apt-get install mycroft-core -y

# Enable ufw for a simple firewall allowing only port 22 incoming as well as dns, dhcp, and the Mycroft web socket
sudo apt-get install ufw -y
#Block all incoming by default
sudo ufw default deny incoming
#Allow ssh on port 22 when enabled
sudo ufw allow 22
#WiFi setup client: Allow tcp connection to websocket
sudo ufw allow in from 172.24.1.0/24 to any port 8181 proto tcp
#Allow tcp to web server
sudo ufw allow in from 172.24.1.0/24 to any port 80 proto tcp
#Allow udp for dns
sudo ufw allow in from 172.24.1.0/24 to any port 53 proto udp
#Allow udp for dhcp
sudo ufw allow in from 0.0.0.0 port 68 to 255.255.255.255 port 67 proto udp
#Turn on the firewall
sudo ufw enable

#Disable kernel boot TTY on GPIO UART
sudo systemctl stop serial-getty@ttyAMA0.service
sudo systemctl disable serial-getty@ttyAMA0.service
#Enable systemd-timesyncd
sudo timedatectl set-ntp true

#Upgrade all packages except raspberrypi-kernel
sudo apt-get update
echo "raspberrypi-kernel hold" | sudo dpkg --set-selections
sudo apt-get upgrade -y

# packagekit setup
sudo apt-get install packagekit -y

#Install librespot
curl -sL https://dtcooper.github.io/raspotify/install.sh | sh
#Then disable the raspotify service:
sudo systemctl stop raspotify sudo systemctl disable raspotify

