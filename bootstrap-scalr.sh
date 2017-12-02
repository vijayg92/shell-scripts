#!/bin/bash

set -o errexit
set -o nounset
set -o pipefail

################################################################################
# Configurable options
################################################################################
# Use Global Variables to submit values.
: ${UAI:=""}
: ${CONFIG_ENV:=""}
: ${CONFIG_BUCKET:=""}
: ${CONFIG_ROLE:=""}
: ${SMTP_RELAY_HOST:=""}

FARM_NAME=${SCALR_FARM_NAME}
FARM_ROLE=${SCALR_FARM_ROLE_ALIAS}

################################################################################
#######                   Initialize Main Program                        #######
################################################################################
service iptables stop
setenforce 0
umask 0022

##### AWS_CLI Installation #####
if pip freeze -q | grep "awscli"; then
    echo "AWS-CLI is Already Installated!!!"
else
    echo "Installing AWS-CLI..."
    pip install awscli
fi

##### Configuring Postfix Relay #####
echo "Configuring Postfix..."
if rpm -qa | grep postix; then
    echo "Installing Postfix..."
    yum install postfix -y
    echo "Configuring SMTP Relay Host..."
    sed -ie 's/#relayhost = uucphost/relayhost = ${SMTP_RELAY_HOST}/g' /etc/postfix/main.cf
else
    echo "Configuring SMTP Relay Host..."
    sed -ie 's/#relayhost = uucphost/relayhost = ${SMTP_RELAY_HOST}/g' /etc/postfix/main.cf
fi
/etc/init.d/postfix start && chkconfig postfix on

##### Puppet Client Setup #####
echo "Configuring Puppet..."
if rpm -qa | grep puppet  ; then
	echo "Puppet is Already Installed !!!"
  echo "Initializing Puppet Agent Run !!!"
  puppet agent --verbose --ignorecache -t
else
	yum install -y puppet
	echo "Creating Puppet Directories !!!"
	echo export FACTER_role="yolab-production" >> /etc/bashrc
    mkdir -p /appl/puppet/var /appl/puppet/run /appl/puppet/log
	echo "Download Puppet Config !!!"
	wget -O /etc/puppet/puppet.conf http://rpm.dbt.corporate.ge.com/puppet_aws/prod/puppet.conf
	wget -O /etc/puppet/namespaceauth.conf http://rpm.dbt.corporate.ge.com/puppet_aws/prod/namespaceauth-aws.conf
	echo "Configure Host Entry For Hostname, Pupppet ELB !!!"
	local_ip4=`curl http://169.254.169.254/latest/meta-data/local-ipv4 2>/dev/null`
	local_hostname=`curl http://169.254.169.254/latest/meta-data/local-hostname 2>/dev/null`
	echo ${local_ip4} ${local_hostname} `hostname` >> /etc/hosts
	echo 10.227.79.110 internal-corp-techsolns-puppet-UAI2000370-2035020617.us-east-1.elb.amazonaws.com ip-10-227-79-110 >> /etc/hosts
  	/etc/init.d/puppet start && chkconfig puppet on
fi
puppet agent --verbose --ignorecache -t
echo "Node has been sucessfully configured !!!"
