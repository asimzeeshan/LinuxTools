#!/bin/bash
## Obserivum Client Setup Script (for Debian, Ubuntu & CentOS)
## v.0.5 - Dec 15. 2013 - nunim@sonicboxes.com
## Original GIST https://gist.github.com/anonymous/10563603
## v 0.6 - Feb 05, 2015 - asim [@] techbytes.pk
## Usage:
# wget --no-check-certificate https://raw.github.com/asimzeeshan/LinuxTools/master/observium-client.sh -O observium-client.sh
# chmod +x observium-client.sh
# ./observium-client.sh <Community> <Contact Email> <Location>

############################################################
# core functions
############################################################
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

function print_critical {
    echo -n -e '\e[1;37;41m'
    echo -n $1
    echo -e '\e[0m'
}

############################################################
# Let's begin
############################################################
if [ $(whoami) != "root" ]; then
        echo "You need to run this script as root."
        echo "Use 'sudo ./observium-client.sh <Community> <Contact Email> <Location>' then enter your password when prompted."
        exit 1
fi

## set community
COMMUNITY=$1
## set contact email
CONTACT=$2
## set Location
LOCATION=$3

## set hostname
#HOSTNAME=$(hostname -f)
## set distro
DISTRO=`cat /etc/*-release | grep -m 1 CentOS | awk {'print $1}'`
## check if community set
if [ -z "$COMMUNITY" ] ; then
        print_critical "Community is not set"
        read -p "Please enter the COMMUNITY: " COMMUNITY
fi

## check if contact email is set
if [ -z "$CONTACT" ] ; then
        print_critical "Contact Email is not set"
        read -p "Please enter the CONTACT Email: " COMMUNITY
fi

## set server location
read -p "Please enter where the server is physically located: " LOCATION
## check distro
if [ "$DISTRO" = "CentOS" ] ; then
        print_info "The OS is detected as CentOS"
        # clear yum cache
        yum clean all
        # install snmp daemon
        yum -y install net-snmp
        # take backup of the original config file
        print_info "Backup up the previous config as /etc/snmp/snmpd_conf.old"
        mv /etc/snmp/snmpd.conf /etc/snmp/snmpd.conf.old
        # set SNMP Daemon options
# sed -i.bak '/OPTIONS=/c\OPTIONS="-Lsd -Lf /dev/null -p /var/run/snmpd.pid"' /etc/sysconfig/snmpd.options
        # attempting to write the file on our own
        cat /etc/sysconfig/snmpd.options | grep SNMPDOPTS
        print_warn "Attempting to fix the snmpd defaults automagically..."
        sed -i -e '/SNMPDOPTS=/s/=.*/="-Lsd -Lf \/dev\/null -u snmp -I -smux -p \/var\/run\/snmpd.pid -c \/etc\/snmp\/snmpd.conf"/' /etc/sysconfig/snmpd.options
        cat /etc/sysconfig/snmpd.options | grep SNMPDOPTS
        print_info "... Done"
else
        print_info "The OS is probably Debian/Ubuntu"
        # update package list
        apt-get update
        # install snmp daemon
        apt-get -y install snmp snmpd
        # take backup of the original config file
        print_info "Backup up the previous config as /etc/snmp/snmpd_conf.old"
        mv /etc/snmp/snmpd.conf /etc/snmp/snmpd.conf.old

        # attempting to write the file on our own
        cat /etc/default/snmpd | grep SNMPDOPTS
        print_warn "Attempting to fix the snmpd defaults automagically..."
        sed -i -e '/SNMPDOPTS=/s/=.*/="-Lsd -Lf \/dev\/null -u snmp -I -smux -p \/var\/run\/snmpd.pid -c \/etc\/snmp\/snmpd.conf"/' /etc/default/snmpd
        cat /etc/default/snmpd | grep SNMPDOPTS
        print_info "... Done"
fi
print_info "Writing the config file /etc/snmp/snmpd.conf"
cat > /etc/snmp/snmpd.conf <<END
com2sec readonly  default         $COMMUNITY
group $COMMUNITY v1         readonly
group $COMMUNITY v2c        readonly
group $COMMUNITY usm        readonly
view all    included  .1                               80
access $COMMUNITY ""      any       noauth    exact  all    none   none
syslocation $LOCATION
syscontact $CONTACT
#This line allows Observium to detect the host OS if the distro script is installed
extend .1.3.6.1.4.1.2021.7890.1 distro /usr/bin/distro
END
print_info "... Done"
# get distro checking script from Observium
wget --no-check-certificate https://raw.github.com/asimzeeshan/LinuxTools/master/distro -O /usr/bin/distro
chmod 755 /usr/bin/distro
/etc/init.d/snmpd restart
print_info "If you need to update COMMUNITY etc please refer to the file '/etc/snmp/snmpd.conf'"

# check IPv4
print_info "Checking for valid IPv4 in eth0"
ipv4=`ifconfig eth0 | awk '/inet addr/ {split ($2,A,":"); print A[2]}'`
if [[ -z $ipv4 ]]
then
    print_info "Checking for valid IPv4 in venet0:0"
    ipv4=`ifconfig venet0:0 | awk '/inet addr/ {split ($2,A,":"); print A[2]}'`
fi


clear
print_critical "############################################################"
print_critical "#             !! !! Installation Complete !! !!            #"
print_critical "############################################################"
print_critical "# You may add this server to your Observium installation   #"
print_critical "#          using the Community name                        #"
print_info     "#          $COMMUNITY"
print_critical "############################################################"
print_critical "# You can verify the functionality by running              #"
print_critical "# snmpwalk -v 2c -c $COMMUNITY $ipv4 "
print_critical "############################################################"
print_critical "#If ufw is installed & configured, do the following        #"
print_critical "# sudo ufw allow from <ObserviumIP> to any port 161 && sudo ufw allow from <ObserviumIP> to any port 199 "
print_critical "############################################################"
