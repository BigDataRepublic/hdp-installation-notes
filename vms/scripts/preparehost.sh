#!/usr/bin/env bash

# Helper functions

CHANGED=0

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
  CHANGED+=1
fi

## Copy correct hosts file to /etc/hosts
HOSTS_CLUSTER_MD5=$(md5sum /vagrant/conf/hosts | cut -d ' ' -f 1)
HOSTS_NODE_MD5=$(md5sum /etc/hosts | cut -d ' ' -f 1)

if [[ $HOSTS_CLUSTER_MD5 != $HOSTS_NODE_MD5 ]]; then
    echo "* Copying hosts file to /etc/hosts..."
    cp /vagrant/conf/hosts /etc/hosts
    chown root:root /etc/hosts
    CHANGED+=1
fi

exit $CHANGED