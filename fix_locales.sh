#!/bin/bash
# Fix the notorious problem that shows the following 
#
# --------------------------------------------------------
# perl: warning: Setting locale failed.
# perl: warning: Please check that your locale settings:
# 	LANGUAGE = (unset),
# 	LC_ALL = (unset),
# 	LANG = "en_US.utf8"
#     are supported and installed on your system.
# perl: warning: Falling back to the standard locale ("C").
# --------------------------------------------------------
#
# Tested on Ubuntu 12.04 32bit
# Tested on Virtualization type: OpenVZ
#
# By: Asim Zeeshan
# http://www.asim.pk/
#

apt-get install -q -y multipath-tools
export LANGUAGE=en_US.UTF-8
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8
locale-gen en_US.UTF-8
dpkg-reconfigure locales