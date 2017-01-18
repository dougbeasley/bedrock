#!/usr/bin/env bash
set -e

#TODO I think the default policy is ACCEPT, so this might not be necissary
sudo iptables -I INPUT -s 0/0 -p tcp --dport 8300 -j ACCEPT
sudo iptables -I INPUT -s 0/0 -p tcp --dport 8301 -j ACCEPT
sudo iptables -I INPUT -s 0/0 -p tcp --dport 8302 -j ACCEPT
sudo iptables -I INPUT -s 0/0 -p tcp --dport 8400 -j ACCEPT

sudo iptables -A INPUT -s 0/0 -p tcp --dport 53 -j ACCEPT
sudo iptables -A INPUT -s 0/0 -p udp --dport 53 -j ACCEPT
sudo iptables -A INPUT -s 0/0 -p tcp --dport 8600 -j ACCEPT
sudo iptables -A INPUT -s 0/0 -p udp --dport 8600 -j ACCEPT

#DNS forwarding
sudo iptables -t nat -I PREROUTING -p udp -d 10.128.0.0/20 --dport 53 -j DNAT --to-destination 127.0.0.1:8600
sudo iptables -t nat -I PREROUTING -p tcp -d 10.128.0.0/20 --dport 53 -j DNAT --to-destination 127.0.0.1:8600
sudo iptables -t nat -I OUTPUT -p tcp -o lo --dport 53 -j REDIRECT --to-ports 8600
sudo iptables -t nat -I OUTPUT -p udp -o lo --dport 53 -j REDIRECT --to-ports 8600

if [ -d /etc/sysconfig ]; then
  sudo iptables-save | sudo tee /etc/sysconfig/iptables
else
  sudo iptables-save | sudo tee /etc/iptables.rules
fi

#update the local net routing
sudo echo "net.ipv4.conf.eth0.route_localnet=1" | sudo tee -a /etc/sysctl.conf
sudo sysctl -p
