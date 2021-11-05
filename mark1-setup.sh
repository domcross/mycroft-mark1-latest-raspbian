#!/usr/bin/env bash

sudo apt-get update

sudo apt-get install nano wget jq -y
bash -c 'echo "alias ll='ls -l" >> /home/pi/.bashrc'
sudo apt-get install apt-transport-https -y
sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys F3B1AA8B
sudo bash -c 'echo "deb http://repo.mycroft.ai/repos/apt/debian debian main" > /etc/apt/sources.list.d/repo.mycroft.ai.list'
sudo apt-get update

# mycroft-python package has a dependency to libgdbm3 which is no longer distributed in current Raspbian OS (Buster)
wget http://ftp.debian.org/debian/pool/main/g/gdbm/libgdbm3_1.8.3-14_armhf.deb
sudo dpkg -i libgdbm3_1.8.3-14_armhf.deb
sudo apt-get install mycroft-core -y

#Add initial config for platform detection
sudo mkdir -p /etc/mycroft
sudo touch /etc/mycroft/mycroft.conf
cp /etc/mycroft/mycroft.conf .
echo "$(jq '. + {"enclosure": {"platform": "mycroft_mark_1","platform_build": 3,"port": "/dev/ttyAMA0","rate": 9600,"timeout": 5.0,"update": true,"test": false}}' mycroft.conf)" > mycroft.conf
echo "$(jq '. + {"VolumeSkill": {"default_level": 6,"min_volume": 0,"max_volume": 83}}' mycroft.conf)" > mycroft.conf
echo "$(jq '. + {"ipc_path": "/ramdisk/mycroft/ipc/"}' mycroft.conf)" > mycroft.conf
sudo rm /etc/mycroft/mycroft.conf && sudo cp mycroft.conf /etc/mycroft/
rm mycroft.conf

# set default sample rate
sudo sed -i 's/^; default-sample-rate = 44100/default-sample-rate = 44100/' /etc/pulse/daemon.conf 

# Edit boot configuration settings in /boot/config.txt
# Uncomment all of these to enable the optional hardware interfaces (about 10 lines from bottom)
sudo sed -i 's/^#dtparam=i2c_arm=on/dtparam=i2c_arm=on/' /boot/config.txt
sudo sed -i 's/^#dtparam=i2s=on/dtparam=i2s=on/' /boot/config.txt
sudo sed -i 's/^#dtparam=spi=on/dtparam=spi=on/' /boot/config.txt
# Comment out the following to disable audio (loads snd_bcm2835)
sudo sed -i 's/^dtparam=audio=on/#dtparam=audio=on/' /boot/config.txt
# Add the following lines at the bottom:
sudo echo '# Disable Bluetooth, it interferes with serial port' >> /boot/config.txt
sudo echo 'dtoverlay=pi3-disable-bt' >> /boot/config.txt
sudo echo 'dtoverlay=pi3-miniuart-bt' >> /boot/config.txt
sudo echo '# Enable Mark 1 soundcard drivers' >> /boot/config.txt
sudo echo 'dtoverlay=rpi-proto' >> /boot/config.txt

# edit /boot/cmdline.txt
# Make sure it contains no mention of ttyAMA0, as this is where the boot logging to serial would be enabled in the past.
#Delete this option: 'console=serial0,115200'
sudo sed -i 's/console=serial0,115200//' /boot/cmdline.txt

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

