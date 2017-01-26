#!/bin/bash

set -e

apt-get update --fix-missing
apt-cache policy docker-engine
apt-get -y install docker-engine
