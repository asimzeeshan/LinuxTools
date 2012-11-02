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

        #workaround for some broken templates on VPS
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

function update_upgrade {
        # Run through the apt-get update/upgrade first. This should be done before
        # we try to install any package
        apt-get -q -y update
        apt-get -q -y upgrade
}

function update_timezone {
        dpkg-reconfigure tzdata
}

function remove_unneeded {
        # Some Debian have portmap installed. We don't need that.
        check_remove portmap portmap

        # Remove rsyslogd, which allocates ~30MB privvmpages on an OpenVZ system,
        # which might make some low-end VPS inoperatable. We will do this even
        # before running apt-get update.
        check_remove rsyslogd rsyslog

        # Other packages that seem to be pretty common in standard OpenVZ
        # templates.
        check_remove apache2 'apache2*'
        check_remove samba 'samba*'
        check_remove nscd nscd

        # Need to stop sendmail as removing the package does not seem to stop it.
                invoke-rc.d sendmail stop
                check_remove sendmail 'sendmail*'
}

############################################################
# Get system updated
############################################################
print_info "Detecting OS ..."
os_summary

print_info "updating repos and upgrading packages"
update_upgrade
remove_unneeded

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
check_install landscape-common

############################################################
# Download lowendscript from GitHub.com
############################################################
print_info "Now downloading scripts from GitHub.com"
wget https://github.com/asimzeeshan/lowendscript/raw/master/setup-debian.sh -O debian.sh && chmod 770 debian.sh
print_info "Downloaded https://github.com/asimzeeshan/lowendscript/setup-debian.sh"

wget http://labs.asimz.com/setup.sh -O setup.sh && chmod 770 setup.sh
print_info "Downloaded http://labs.asimz.com/setup.sh"

wget https://github.com/asimzeeshan/VPS/raw/master/fix_locales.sh -O fix_locales.sh && chmod 770 fix_locales.sh
print_info "Downloaded fix_locales.sh"

dpkg-reconfigure landscape-common

/root/setup.sh nagiosclient
print_info "NagiosClient installed, now removing unneeded packages again"

remove_unneeded

print_info "I believe thats all what was needed, Happy VPS-ing"
print_info "(until the next time I find something to add to this script)"
