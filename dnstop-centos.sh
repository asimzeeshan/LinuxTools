#!/bin/sh
############################################################
# Install dnstop on CentOS
############################################################
yum install libpcap-devel ncurses-devel
mkdir ~/tmp/
cd ~/tmp/
wget http://dns.measurement-factory.com/tools/dnstop/src/dnstop-20140915.tar.gz
tar -zxvf dnstop-20140915.tar.gz
cd dnstop-20140915
./configure
make && make install
