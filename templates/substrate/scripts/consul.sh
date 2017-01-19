#!/usr/bin/env bash
set -e

echo "Fetching Consul..."
CONSUL=0.7.2
cd /tmp
wget -q https://releases.hashicorp.com/consul/${CONSUL}/consul_${CONSUL}_linux_amd64.zip -O consul.zip

echo "Installing Consul..."
unzip -o consul.zip >/dev/null
chmod +x consul
sudo mv consul /usr/local/bin/consul
sudo mkdir -p /opt/consul/data

echo "Installing Upstart service..."
sudo mkdir -p /etc/consul.d
sudo mkdir -p /etc/service
sudo chown root:root /tmp/consul-upstart.conf
sudo mv /tmp/consul-upstart.conf /etc/init/consul.conf
sudo chmod 0644 /etc/init/consul.conf
#sudo mv /tmp/consul_flags /etc/service/consul
#sudo chmod 0644 /etc/service/consul
