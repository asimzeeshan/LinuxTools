#!/bin/bash
# Show motd on Ubuntu only because no such utility exists on Debian at the moment
# 
# Tested on Ubuntu 12.04
# Tested on Virtualization type: OpenVZ, KVM, XEN-PV
# 
# By: Asim Zeeshan
# http://www.asim.pk/

apt-get clean all
apt-get -q -y autoremove
apt-get update
apt-get -q -y upgrade
apt-get -q -y install landscape-common
dpkg-reconfigure landscape-common