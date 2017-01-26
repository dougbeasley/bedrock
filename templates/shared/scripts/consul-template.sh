#!/usr/bin/env bash
set -e



CT_VERSION=0.18.0

echo "Donwloading Consul Template..."
wget https://releases.hashicorp.com/consul-template/${CT_VERSION}/consul-template_${CT_VERSION}_linux_amd64.zip -O consul-template.zip

echo "Installing Consul Template..."
unzip -o consul-template.zip >/dev/null
chmod +x consul-template
sudo mv consul-template /usr/local/bin/consul-template
