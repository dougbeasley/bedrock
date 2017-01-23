#!/usr/bin/env bash
set -e

echo "Fetching Nomad..."
NOMAD=0.5.2
cd /tmp
wget -q https://releases.hashicorp.com/nomad/${NOMAD}/nomad_${NOMAD}_linux_amd64.zip -O nomad.zip

sudo useradd nomad

echo "Installing Nomad..."
unzip -o nomad.zip >/dev/null
chmod +x nomad
sudo mv nomad /usr/local/bin/nomad
sudo mkdir -p /var/nomad/data
sudo chown -R nomad /var/nomad
