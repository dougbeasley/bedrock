#!/bin/bash

set -vx

echo "deb http://http.debian.net/debian wheezy-backports main" > /etc/apt/sources.list.d/backports.list

apt-get update
apt-get purge "lxc-docker*"
apt-get purge "docker.io*"

apt-get update
apt-get -y install apt-transport-https ca-certificates gnupg2

apt-key adv \
       --keyserver hkp://ha.pool.sks-keyservers.net:80 \
       --recv-keys 58118E89F3A912897C070ADBF76221572C52609D

echo "deb https://apt.dockerproject.org/repo debian-jessie main"  > /etc/apt/sources.list.d/docker.list

#TODO DRY this out a bit
apt-get update
apt-get update --fix-missing
apt-cache policy docker-engine

apt-get -y install docker-engine dnsutils
