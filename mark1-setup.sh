#!/usr/bin/env bash

sudo apt-get update
sudo apt-get install nano wget jq -y
sudo apt-get install apt-transport-https -y
sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys F3B1AA8B
sudo bash -c 'echo "deb http://repo.mycroft.ai/repos/apt/debian debian main" > /etc/apt/sources.list.d/repo.mycroft.ai.list'
sudo apt-get update

echo '# install zram'
sudo wget -q https://git.io/vM1kx -O /tmp/rpizram && bash /tmp/rpizram

echo '# Create RAM disk for IPC'
sudo mkdir -p /ramdisk
sudo bash -c 'echo "tmpfs /ramdisk tmpfs rw,nodev,nosuid,size=20M 0 0" >> /etc/fstab'

echo 'rustup - Rust is required for some default skills'
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- --default-toolchain nightly

echo '# packagekit setup'
sudo apt-get install packagekit -y
echo '# Allow mycroft user to install with pip'
sudo bash -c 'echo "mycroft ALL=(ALL) NOPASSWD: /usr/local/bin/pip install *" > /etc/sudoers.d/011_mycroft-nopasswd'
sudo chmod -w /etc/sudoers.d/011_mycroft-nopasswd

echo '# install PulseAudio, ALSA config'
sudo apt-get install pulseaudio alsa-utils 
# anonymous auth for PA
sudo sed -i 's/^load-module module-native-protocol-unix/load-module module-native-protocol-unix auth-anonymous=1/' /etc/pulse/system.pa 
# set default sample rate
sudo sed -i 's/^; default-sample-rate = 44100/default-sample-rate = 44100/' /etc/pulse/daemon.conf 
echo '# Edit boot configuration settings in /boot/config.txt'
# Uncomment all of these to enable the optional hardware interfaces
sudo sed -i 's/^#dtparam=i2c_arm=on/dtparam=i2c_arm=on/' /boot/config.txt
sudo sed -i 's/^#dtparam=i2s=on/dtparam=i2s=on/' /boot/config.txt
sudo sed -i 's/^#dtparam=spi=on/dtparam=spi=on/' /boot/config.txt
# Comment out the following to disable audio (loads snd_bcm2835)
sudo sed -i 's/^dtparam=audio=on/#dtparam=audio=on/' /boot/config.txt
# Add the following lines at the bottom:
sudo bash -c 'echo "# Disable Bluetooth, it interferes with serial port" >> /boot/config.txt'
sudo bash -c 'echo "dtoverlay=pi3-disable-bt" >> /boot/config.txt'
sudo bash -c 'echo "dtoverlay=pi3-miniuart-bt" >> /boot/config.txt'
sudo bash -c 'echo "# Enable Mark 1 soundcard drivers" >> /boot/config.txt'
sudo bash -c 'echo "dtoverlay=rpi-proto" >> /boot/config.txt'

echo '# edit /boot/cmdline.txt'
# Make sure it contains no mention of ttyAMA0, as this is where the boot logging to serial would be enabled in the past.
#Delete this option: 'console=serial0,115200'
sudo sed -i 's/console=serial0,115200//' /boot/cmdline.txt

echo '# Enable ufw for a simple firewall allowing only port 22 incoming as well as dns, dhcp, and the Mycroft web socket'
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
sudo ufw --force enable

echo '# Disable kernel boot TTY on GPIO UART'
sudo systemctl stop serial-getty@ttyAMA0.service
sudo systemctl disable serial-getty@ttyAMA0.service

echo '# Enable systemd-timesyncd'
sudo timedatectl set-ntp true

echo '# Upgrade all packages except raspberrypi-kernel'
sudo apt-get update
echo "raspberrypi-kernel hold" | sudo dpkg --set-selections
sudo apt-get upgrade -y

echo '# Install librespot'
curl -sL https://dtcooper.github.io/raspotify/install.sh | sh
#Then disable the raspotify service:
sudo systemctl stop raspotify 
sudo systemctl disable raspotify

echo '... please reboot, then continue with script "mark1-setup2.sh"'
