# Ambari agent preparation

**Goal:** Prepare cluster nodes for interaction with the Ambari agent server by manually installing ambari-agent.

**Rationale:** The alternative approach requires passwordless login over ssh from ambari-server to all hosts managed by Ambari. This could be considered a security issue as a breach of the ambari-server would give ssh access to all nodes in the cluster.



[See for details](http://www.slideshare.net/hortonworks/ambari-agentregistrationflow-17041261)

# Install the ambari-agent

This procedure describe the steps to install ambari agent and start the process. We will configure the agent to run as the ambari user (as opposed to root). These steps need to be repeated for each node. **NOTE:** This includes the host that is running ambari-server. For automated preparation see [below](#automated-preparation-of-host).


1. Login to the host and become root - Repeat the hosts steps in this documents by replacing *gw* below, by one of: en, mn1, mn2 and wn1. **NOTE:** All steps must be completed for all hosts before you can continue with the next chapter.
```
you@yourhost $ cd /path/to/tutorialdir/vms
you@yourhost $ vagrant up
you@yourhost $ vagrant ssh en
vagrant@$en.bdr.nl $ sudo su -
root@$en.bdr.nl $
```

1. Install java openjdk 1.8.0

  ```
  root@$en.bdr.nl $ yum install -y java-1.8.0-openjdk
  ```

1. Install ambari agent
```
root@$en.bdr.nl $ wget -nv http://public-repo-1.hortonworks.com/ambari/centos7/2.x/updates/2.2.2.0/ambari.repo -O /etc/yum.repos.d/ambari.repo
root@$en.bdr.nl $ yum install ambari-agent -y
```

1. Adapt the configuration - We need to adapt the configuration of the agent to make sure it connects with ambari-server and to make sure it does not run as root.
```
root@$gw.bdr.nl $ vi /etc/ambari-agent/conf/ambari-agent.ini
```
Search for the following properties and set the values as described:

  ```
  [server]
  hostname=en.bdr.nl

  [agent]
  run_as_user=ambari
```

1. Verify that the ambari user exists and has sudo rights

  ```
  root@$en.bdr.nl $ id ambari
  uid=1001(ambari) gid=1001(ambari) groups=1001(ambari)
  ```

  If the user does not exist, add the user as follows:

  ```
  root@$en.bdr.nl $ useradd ambari
  ```

  To add the proper sudo rights for ambari run visudo and add the following lines
  at the bottom of the file:

  ```
  root@$en.bdr.nl $ visudo
  # Ambari Customizable Users
  ambari ALL=(ALL) NOPASSWD:SETENV: /bin/su hdfs *,/bin/su ambari-qa *,/bin/su ranger *,/bin/su zookeeper *,/bin/su knox *,/bin/su falcon *,/bin/su ams *, /bin/su flume *,/bin/su hbase *,/bin/su spark *,/bin/su accumulo *,/bin/su hive *,/bin/su hcat *,/bin/su kafka *,/bin/su mapred *,/bin/su oozie *,/bin/su sqoop *,/bin/su storm *,/bin/su tez *,/bin/su atlas *,/bin/su yarn *,/bin/su kms *

  # Ambari Commands
  ambari ALL=(ALL) NOPASSWD:SETENV: /usr/bin/yum,/usr/bin/zypper,/usr/bin/apt-get, /bin/mkdir, /usr/bin/test, /bin/ln, /bin/chown, /bin/chmod, /bin/chgrp, /usr/sbin/groupadd, /usr/sbin/groupmod, /usr/sbin/useradd, /usr/sbin/usermod, /bin/cp, /usr/sbin/setenforce, /usr/bin/test, /usr/bin/stat, /bin/mv, /bin/sed, /bin/rm, /bin/kill, /bin/readlink, /usr/bin/pgrep, /bin/cat, /usr/bin/unzip, /bin/tar, /usr/bin/tee, /bin/touch, /usr/bin/hdp-select, /usr/bin/conf-select, /usr/hdp/current/hadoop-client/sbin/hadoop-daemon.sh, /usr/lib/hadoop/bin/hadoop-daemon.sh, /usr/lib/hadoop/sbin/hadoop-daemon.sh, /sbin/chkconfig gmond off, /sbin/chkconfig gmetad off, /etc/init.d/httpd *, /sbin/service hdp-gmetad start, /sbin/service hdp-gmond start, /usr/sbin/gmond, /usr/sbin/update-rc.d ganglia-monitor *, /usr/sbin/update-rc.d gmetad *, /etc/init.d/apache2 *, /usr/sbin/service hdp-gmond *, /usr/sbin/service hdp-gmetad *, /sbin/service mysqld *, /usr/bin/python2.6 /var/lib/ambari-agent/data/tmp/validateKnoxStatus.py *, /usr/hdp/current/knox-server/bin/knoxcli.sh *, /usr/bin/dpkg *, /bin/rpm *, /usr/sbin/hst *

  # Ambari Ranger Commands
  ambari ALL=(ALL) NOPASSWD:SETENV: /usr/hdp/*/ranger-usersync/setup.sh, /usr/bin/ranger-usersync-stop, /usr/bin/ranger-usersync-start, /usr/hdp/*/ranger-admin/setup.sh *, /usr/hdp/*/ranger-knox-plugin/disable-knox-plugin.sh *, /usr/hdp/*/ranger-storm-plugin/disable-storm-plugin.sh *, /usr/hdp/*/ranger-hbase-plugin/disable-hbase-plugin.sh *, /usr/hdp/*/ranger-hdfs-plugin/disable-hdfs-plugin.sh *,  /usr/hdp/current/ranger-admin/ranger_credential_helper.py, /usr/hdp/current/ranger-kms/ranger_credential_helper.py, /usr/hdp/*/ranger-*/ranger_credential_helper.py
  ```

1. Start the ambari agent

  ```
  root@$en.bdr.nl $ systemctl start ambari-agent
  ```

# Automated preparation of host

To save you some time we have automated above deployment steps. You can prepare
another host in an automnated fashion as follows:

```
you@yourhost $ cd /path/to/tutorialdir/vms
you@yourhost $ vagrant up
you@yourhost $ vagrant ssh wn1
vagrant@$wn1.bdr.nl $ bash /vagrant/scripts/prepare_ambari-agent_host.sh
```

Repeat these steps for the following hosts:

* mn1.bdr.nl
* mn2.bdr.nl
* wn1.bdr.nl
* gw.bdr.nl

# When things go wrong

If your ambari-agent does not start correctly you can try to find out what went wrong by looking into the following log files:

* /var/log/ambari-agent/ambari-agent.out (application output to stdout)
* /var/log/ambari-agent/ambari-agent.log (application generated log)

Additionally, you could edit /etc/ambari-agent/conf/logging.conf.sample and change the log level to DEBUG. **NOTE:** Whenever you change log levels to DEBUG, make sure to revert the change when you have solved the issue. Some of the applications in the Hadoop stack produce enormous amounts of logs in DEBUG mode. For info on log4j log levels, see e.g. [here](https://logging.apache.org/log4j/1.2/apidocs/org/apache/log4j/Level.html).
