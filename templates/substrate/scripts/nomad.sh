#!/usr/bin/env bash
set -e

echo "Fetching Nomad..."
NOMAD=0.5.2
cd /tmp
wget -q https://releases.hashicorp.com/nomad/${NOMAD}/nomad_${NOMAD}_linux_amd64.zip -O nomad.zip

echo "Installing Nomad..."
unzip -o nomad.zip >/dev/null
chmod +x nomad
sudo mv nomad /usr/local/bin/nomad
sudo mkdir -p /opt/nomad/data

echo "Installing Upstart service..."
sudo mkdir -p /etc/nomad.d
sudo mkdir -p /etc/service
sudo chown root:root /tmp/nomad-upstart.conf
sudo mv /tmp/nomad-upstart.conf /etc/init/nomad.conf
sudo chmod 0644 /etc/init/nomad.conf
#sudo mv /tmp/nomad_flags /etc/service/nomad
#sudo chmod 0644 /etc/service/nomad
