echo '# install mycroft-core'
# mycroft-python package has a dependency to libgdbm3 which is no longer distributed in current Raspbian OS (Buster)
wget http://ftp.debian.org/debian/pool/main/g/gdbm/libgdbm3_1.8.3-14_armhf.deb
sudo dpkg -i libgdbm3_1.8.3-14_armhf.deb
sudo apt-get install mycroft-core -y

echo '# Add initial config for platform detection'
sudo mkdir -p /etc/mycroft
sudo touch /etc/mycroft/mycroft.conf
cp /etc/mycroft/mycroft.conf .
echo "$(jq '. + {"enclosure": {"platform": "mycroft_mark_1","platform_build": 3,"port": "/dev/ttyAMA0","rate": 9600,"timeout": 5.0,"update": true,"test": false}}' mycroft.conf)" > mycroft.conf
echo "$(jq '. + {"VolumeSkill": {"default_level": 6,"min_volume": 0,"max_volume": 83}}' mycroft.conf)" > mycroft.conf
echo "$(jq '. + {"ipc_path": "/ramdisk/mycroft/ipc/"}' mycroft.conf)" > mycroft.conf
sudo rm /etc/mycroft/mycroft.conf && sudo cp mycroft.conf /etc/mycroft/
#rm mycroft.conf

sudo chown -R mycroft:mycroft /opt/mycroft/*
