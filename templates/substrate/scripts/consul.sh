#!/usr/bin/env bash
set -e

echo "Fetching Consul..."
CONSUL=0.7.2
cd /tmp
wget -q https://releases.hashicorp.com/consul/${CONSUL}/consul_${CONSUL}_linux_amd64.zip -O consul.zip

sudo useradd -m -d /var/consul consul

echo "Installing Consul..."
unzip -o consul.zip >/dev/null
chmod +x consul
chown consul consul
sudo mv consul /usr/local/bin/consul
sudo mkdir -p /var/consul/data
sudo chown -R consul /var/consul
