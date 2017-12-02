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
: ${TECHSOLNS_BUCKET:=""}
: ${TECHSOLNS_BUCKET_SCRIPTS_FOLDER:=""}
: ${SMTP_RELAY_HOST:=""}

FARM_NAME=${SCALR_FARM_NAME}
FARM_ROLE=${SCALR_FARM_ROLE_ALIAS}

DEVOPS_ACCESS="techsolnsdevopsuseradd"
DEV_ACCESS="techsolnsdevuseradd"

################################################################################
# Initial Setup
################################################################################
service iptables stop
setenforce 0
umask 0022

################################################################################
# Install AWS CLI
################################################################################
if pip freeze -q | grep "awscli"; then
    echo "AWS-CLI is Already Installated!!!"
else
    echo "Installing AWS-CLI..."
    pip install awscli
fi

################################################################################
# Configuring Postfix Relay
################################################################################
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

################################################################################
# DEVOPS and DEV Access
################################################################################
aws s3 cp s3://${TECHSOLNS_BUCKET}/${TECHSOLNS_BUCKET_SCRIPTS_FOLDER}/ /tmp/ --recursive --exclude "*" --include "*.pub"
echo "Setting up access for DevOps team...."
aws s3 cp s3://${TECHSOLNS_BUCKET}/${TECHSOLNS_BUCKET_SCRIPTS_FOLDER}/${DEVOPS_ACCESS} /tmp/${DEVOPS_ACCESS}
sh /tmp/${DEVOPS_ACCESS}
echo "Setting up access for Dev team...."
aws s3 cp s3://${TECHSOLNS_BUCKET}/${TECHSOLNS_BUCKET_SCRIPTS_FOLDER}/${DEV_ACCESS} /tmp/${DEV_ACCESS}
sh /tmp/${DEV_ACCESS}
echo "Clean up....."
rm -f /tmp/${DEVOPS_ACCESS} /tmp/${DEV_ACCESS} /tmp/*.pub

################################################################################
# Puppet Client Setup
################################################################################
echo "Configuring Puppet..."
if rpm -qa | grep puppet  ; then
	echo -e "\nPuppet is Already Installed.!!!"
  echo -e "\nInitializing Puppet Agent Run......."
  puppet agent --verbose --ignorecache -t
else
	yum install -y puppet
	echo -e "\nCreating Puppet Directories...."
    mkdir -p /appl/puppet/var /appl/puppet/run /appl/puppet/log
  echo export FACTER_role="gateway2box-dev" >> /etc/bashrc
	echo -e "\nDownload Puppet Config....."
	wget -O /etc/puppet/puppet.conf http://rpm.dbt.corporate.ge.com/puppet_aws/prod/puppet.conf
	wget -O /etc/puppet/namespaceauth.conf http://rpm.dbt.corporate.ge.com/puppet_aws/prod/namespaceauth-aws.conf
	echo "Configure Host Entry For Hostname, Pupppet ELB !!!"
	local_ip4=`curl http://169.254.169.254/latest/meta-data/local-ipv4 2>/dev/null`
	local_hostname=`curl http://169.254.169.254/latest/meta-data/local-hostname 2>/dev/null`
	echo ${local_ip4} ${local_hostname} `hostname` >> /etc/hosts
	echo 10.227.79.110 internal-corp-techsolns-puppet-UAI2000370-2035020617.us-east-1.elb.amazonaws.com ip-10-227-79-110 >> /etc/hosts
  echo -e "\nInitializing Puppet Agent Run......."
  puppet agent --verbose --ignorecache -t
  /etc/init.d/puppet start && chkconfig puppet on
fi

echo -e "\nNode has been sucessfully configured !!!"
