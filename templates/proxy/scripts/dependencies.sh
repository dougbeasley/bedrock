#!/bin/bash

set -e

echo "deb http://http.debian.net/debian wheezy-backports main" > /etc/apt/sources.list.d/backports.list

sudo apt-get update
sudo apt-get install -y dnsutils unzip resolvconf systemd haproxy
