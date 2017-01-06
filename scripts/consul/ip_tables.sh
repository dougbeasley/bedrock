#!/usr/bin/env bash
set -e

sudo iptables -I INPUT -s 0/0 -p tcp --dport 8300 -j ACCEPT
sudo iptables -I INPUT -s 0/0 -p tcp --dport 8301 -j ACCEPT
sudo iptables -I INPUT -s 0/0 -p tcp --dport 8302 -j ACCEPT
sudo iptables -I INPUT -s 0/0 -p tcp --dport 8400 -j ACCEPT

#DNS forwarding
sudo iptables -I INPUT -s 0/0 -p tcp --dport 53 -j ACCEPT
sudo iptables -t nat -I PREROUTING -p tcp --dport 53 -j REDIRECT --to-ports 8600
sudo iptables -t nat -I PREROUTING -p udp --dport 53 -j REDIRECT --to-ports 8600
sudo iptables -t nat -I OUTPUT -p tcp -o lo --dport 53 -j REDIRECT --to-ports 8600
sudo iptables -t nat -I OUTPUT -p udp -o lo --dport 53 -j REDIRECT --to-ports 8600

if [ -d /etc/sysconfig ]; then
  sudo iptables-save | sudo tee /etc/sysconfig/iptables
else
  sudo iptables-save | sudo tee /etc/iptables.rules
fi
