#!/bin/bash

############################################################
# core functions
############################################################
function check_sanity {
	# Do some sanity checking.
	if [ $(/usr/bin/id -u) != "0" ]
	then
		die 'Must be run by root user'
	fi

	if [ ! -f /etc/debian_version ]
	then
		die "Distribution is not supported"
	fi
}

function check_install {
	if [ -z "`which "$1" 2>/dev/null`" ]
	then
		executable=$1
		shift
		while [ -n "$1" ]
		do
			DEBIAN_FRONTEND=noninteractive apt-get -q -y install "$1"
			print_info "$1 installed successfully"
			shift
        done
	else
		print_warn "$1 already installed"
    fi

	# workaround for some broken templates on VPS
	apt-get -q -y install $1
}

function check_remove {
	if [ -n "`which "$1" 2>/dev/null`" ]
	then
		DEBIAN_FRONTEND=noninteractive apt-get -q -y remove --purge "$1"
		print_info "$1 removed successfully"
	else
		print_warn "$1 is not installed"
	fi
}

function apt_clean_all {
	apt-get clean all
}

function update_upgrade {
	# Run through the apt-get update/upgrade first. This should be done before
	# we try to install any package
	apt-get -q -y update
	apt-get -q -y upgrade

	# also remove the orphaned stuf
	apt-get -q -y autoremove
}

function update_timezone {
	dpkg-reconfigure tzdata
}

function die {
    echo "ERROR: $1" > /dev/null 1>&2
    exit 1
}

function print_info {
    echo -n -e '\e[1;36m'
    echo -n $1
    echo -e '\e[0m'
}

function print_warn {
    echo -n -e '\e[1;33m'
    echo -n $1
    echo -e '\e[0m'
}

############################################################
# Print OS summary (OS, ARCH, VERSION)
############################################################
function os_summary {
	# Thanks for Mikel (http://unix.stackexchange.com/users/3169/mikel) for the code sample which was later modified a bit
	# http://unix.stackexchange.com/questions/6345/how-can-i-get-distribution-name-and-version-number-in-a-simple-shell-script
	ARCH=$(uname -m | sed 's/x86_//;s/i[3-6]86/32/')

	if [ -f /etc/lsb-release ]; then
		. /etc/lsb-release
		OS=$DISTRIB_ID
		VERSION=$DISTRIB_RELEASE
	elif [ -f /etc/debian_version ]; then
		# Work on Debian and Ubuntu alike
		OS=$(lsb_release -si)
		VERSION=$(lsb_release -sr)
	elif [ -f /etc/redhat-release ]; then
		# Add code for Red Hat and CentOS here
		OS=Redhat
		VERSION=$(uname -r)
	else
		# Pretty old OS? fallback to compatibility mode
		OS=$(uname -s)
		VERSION=$(uname -r)
	fi

	OS_SUMMARY=$OS
	OS_SUMMARY+=" "
	OS_SUMMARY+=$VERSION
	OS_SUMMARY+=" "
	OS_SUMMARY+=$ARCH
	OS_SUMMARY+="bit"

	print_info "$OS_SUMMARY"
}

############################################################
# Lets start ...
############################################################
os_summary

print_info "updating Repos and upgrading packages"
apt_clean_all
update_upgrade

print_info "Updating timezone information"
update_timezone

print_info "Installing required packages ..."
check_install nano nano
check_install wget wget
check_install htop htop
check_install iotop iotop
check_install iftop iftop
print_warn "Run IFCONFIG to find your net. device name"
print_warn "Example usage: iftop -i eth0"

check_install mc mc

############################################################
# Download scripts from GitHub.com and other resources
############################################################
print_info "Downloading https://github.com/asimzeeshan/lowendscript/setup-debian.sh ..."
wget https://raw.github.com/asimzeeshan/lowendscript/master/setup-debian.sh 2>&1 -O ~/debian.sh
chmod 770 ~/debian.sh
print_info ".. DONE!"

print_info "Downloading https://github.com/asimzeeshan/DebianTools/raw/master/configure_sysinfo.sh ..."
wget https://raw.github.com/asimzeeshan/DebianTools/master/configure_sysinfo.sh 2>&1 -O ~/configure_sysinfo.sh
chmod 770 ~/configure_sysinfo.sh
print_info ".. DONE!"

print_info "Downloading http://labs.asimz.com/setup.sh ..."
wget http://labs.asimz.com/setup.sh 2>&1 -O ~/setup.sh
chmod 770 ~/setup.sh
print_info ".. DONE!"

print_info "Downloading http://freevps.us/downloads/bench.sh ..."
wget http://freevps.us/downloads/bench.sh 2>&1 -O ~/bench.sh
chmod 770 ~/bench.sh 
print_info ".. DONE!"

print_warn "Over-writing .bashrc from Ubuntu"
wget https://raw.github.com/asimzeeshan/DebianTools/master/bashrc 2>&1 -O ~/.bashrc
print_warn ".. DONE!"

print_warn "Installing NagiosClient"
/root/setup.sh nagiosclient

print_info "I believe thats all what was needed, Happy VPS-ing"
print_info "(until the next time I find something to add to this script)"
