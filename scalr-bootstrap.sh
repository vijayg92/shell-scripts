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
# Library
################################################################################
command_exists() {
  command -v "$@" > /dev/null 2>&1
}

################################################################################
# Initialize
################################################################################
service iptables stop
setenforce 0
umask 0022

################################################################################
# Install AWS CLI
################################################################################
if command_exists "apt-get"; then
  apt-get update
elif command_exists "yum"; then
 yum update -y puppet postgresql
else
  echo "No known package manager found."
  exit 1
fi

# AWS CLI
echo "Install AWS CLI"
pip install awscli
echo "Setting SMTP relay host in postfix"
echo relayhost = "${SMTP_RELAY_HOST}" >> /etc/postfix/main.cf
/etc/init.d/postfix restart



# NEW RELIC Setup
echo "New Relic Server Agent Install"
if rpm -qa | grep newrelic ; then
	echo "New Relic is already installed "
else
	rpm -Uvh https://yum.newrelic.com/pub/newrelic/el5/x86_64/newrelic-repo-5-3.noarch.rpm
	yum install -y newrelic-sysmond
	rm -f /etc/newrelic/nrsysmond.cfg
	wget http://rpm.dbt.corporate.ge.com/puppet_aws/nrsysmond-aws.cfg -O /etc/newrelic/nrsysmond.cfg

	if [ ! -d /logs/newrelic ]; then
		echo "Creating NewRelic log path."
		mkdir -p /logs/newrelic
    	chown -R newrelic:newrelic /logs/newrelic
	else
		echo "NewRelic log path already exists."
	fi
fi

/etc/init.d/newrelic-sysmond restart

# Puppet Client  Setup
if rpm -qa | grep puppet  ; then
	echo "Puppet is already installed "
else
	yum install -y puppet
	echo "Create puppet directories"
	echo export FACTER_role="yolab-aws" >> /etc/bashrc
    mkdir -p /appl/puppet/var /appl/puppet/run /appl/puppet/log
	echo "Download puppet config"
	wget -O /etc/puppet/puppet.conf http://rpm.dbt.corporate.ge.com/puppet_aws/prod/puppet.conf
	wget -O /etc/puppet/namespaceauth.conf http://rpm.dbt.corporate.ge.com/puppet_aws/prod/namespaceauth-aws.conf
	echo "Configure host file for hostname and pupppet elb"
	local_ip4=`curl http://169.254.169.254/latest/meta-data/local-ipv4 2>/dev/null`
	local_hostname=`curl http://169.254.169.254/latest/meta-data/local-hostname 2>/dev/null`
	echo $local_ip4 $local_hostname `hostname` >> /etc/hosts
	echo 10.227.79.110 internal-corp-techsolns-puppet-UAI2000370-2035020617.us-east-1.elb.amazonaws.com ip-10-227-79-110 >> /etc/hosts
fi

echo "Puppet init"
puppet agent --verbose --ignorecache -t
/etc/init.d/puppet start
echo "All Done"
