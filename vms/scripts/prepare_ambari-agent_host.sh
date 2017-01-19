#!/usr/bin/env bash

# Helper functions

function isinstalled {
  if yum list installed "$@" > /dev/null 2>&1; then
    true
  else
    false
  fi
}

function install {
  echo "* Installing $@..."
  sudo yum install -y "$@"
}

if ! isinstalled java-1.8.0-openjdk; then
  install java-1.8.0-openjdk
fi


if [ ! -f /etc/yum.repos.d/ambari.repo ]; then
  echo "* Downloading ambari repository file..."
  sudo wget -nv http://public-repo-1.hortonworks.com/ambari/centos7/2.x/updates/2.2.2.0/ambari.repo -O /etc/yum.repos.d/ambari.repo
fi

if ! isinstalled ambari-agent; then
  install ambari-agent
fi

## Adapt ambari ini
AI_CLUSTER_MD5=$(md5sum /vagrant/conf/ambari-agent.ini | cut -d ' ' -f 1)
AI_NODE_MD5=$(md5sum /etc/ambari-agent/conf/ambari-agent.ini | cut -d ' ' -f 1)

if [[ $AI_CLUSTER_MD5 != $AI_NODE_MD5 ]]; then
  echo "* Copying ambari-agent.ini /etc/ambari-agent/conf..."
  sudo cp /vagrant/conf/ambari-agent.ini /etc/ambari-agent/conf/ambari-agent.ini
  sudo chown root:root /etc/ambari-agent/conf/ambari-agent.ini
fi

if ! id "ambari" >/dev/null 2>&1; then
  echo "* Creating user ambari"
  sudo useradd ambari
fi

## Adapt sudoers
AI_CLUSTER_MD5=$(md5sum /vagrant/conf/sudoers | cut -d ' ' -f 1)
AI_NODE_MD5=$(sudo md5sum /etc/sudoers | cut -d ' ' -f 1)

if [[ $AI_CLUSTER_MD5 != $AI_NODE_MD5 ]]; then
  echo "* Copying sudoers /etc/sudoers..."
  sudo cp /vagrant/conf/sudoers /etc/sudoers
  sudo chown root:root /etc/sudoers
fi

if [[ $(systemctl is-active ambari-agent) == "inactive" ]]; then
  echo "* Starting ambarig-agent..."
  sudo systemctl  start ambari-agent
fi

echo "Done!"
