#!/bin/bash

set -vx

apt-get update --fix-missing
apt-cache policy docker-engine
apt-get -y install docker-engine
