#!/usr/bin/env bash

# Helper functions

function isinstalled {
  if yum list installed "$@" > /dev/null 2>&1; then
    true
  else
    false
  fi
}

# Main

if [[ $EUID -ne 0 ]]; then
  echo "This script must be run as root" 1>&2
  exit 1
fi

## Install bind-utils if needed
if ! isinstalled bind-utils; then
  echo "* Installing bind-utils..."
  yum install -y bind-utils
fi

## Install ntp if needed
if ! isinstalled ntp; then
  echo "* Installing ntp..."
  yum install -y ntp
  systemctl enable ntpd.service
  systemctl start ntpd
fi

if ! isinstalled vim; then
  echo "* Installing vim..."
  # Needed for visudo
  yum install -y vim
fi

if ! isinstalled wget; then
  echo "* Installing vim..."
  # Needed for visudo
  yum install -y wget
fi

## Copy correct hosts file to /etc/hosts
HOSTS_CLUSTER_MD5=$(md5sum /vagrant/conf/hosts | cut -d ' ' -f 1)
HOSTS_NODE_MD5=$(md5sum /etc/hosts | cut -d ' ' -f 1)

if [[ $HOSTS_CLUSTER_MD5 != $HOSTS_NODE_MD5 ]]; then
  echo "* Copying hosts file to /etc/hosts..."
  cp /vagrant/conf/hosts /etc/hosts
  chown root:root /etc/hosts
fi

# Set the correct time zone
HOSTS_ACTUALTZ_MD5=$(md5sum /etc/localtime | cut -d ' ' -f 1)
HOSTS_DESIREDTZ_MD5=$(md5sum /usr/share/zoneinfo/Europe/Amsterdam | cut -d ' ' -f 1)

if [[ $HOSTS_DESIREDTZ_MD5 != $HOSTS_ACTUALTZ_MD5 ]]; then
  mv /etc/localtime /etc/localtime.bkp
  cp /usr/share/zoneinfo/Europe/Amsterdam /etc/localtime
fi

exit 0
