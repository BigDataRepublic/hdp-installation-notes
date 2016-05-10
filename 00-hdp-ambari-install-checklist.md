# Installation checklists for Ambari managed Hortonworks Data Platform

This checklist helps to make sure that an Ambari managed HDP installation runs
as smooth as possible. It assumes a Kerberized installation of HDP. It is
recommended to have a dedicated identity management server for the cluster (e.g
an Active Directory server on Windows or a MIT kerberos on Linux).

## Pre-install

### Misc

* [ ] Package management system is updated on all hosts
* [ ] Timezone is set to the correct timezone on all hosts
* [ ] NTPD on all hosts
    * [ ] is installed
    * [ ] is started at boot
    * [ ] is running

### Networking related

* [ ] Each node has the FQDN set properly
* [ ] Each node has /etc/hosts has configured properly
    * [ ] Mapping to 127.0.0.1 is removed/disabled
    * [ ] All nodes which needs to be managed by Ambari are mapped
* [ ] Each node has /etc/sysconfig/network configured properly
* [ ] Each node has IPv6 is disabled
* [ ] Each node has iptables and/or firewalling disabled
* [ ] SSH-keyless login from Ambari host to other hosts is possible
    * [ ] A public/private keypair is generated on the Ambari host
    * [ ] The Amabari host public key is added to /root/.ssh/authorized keys on all hosts
    * [ ] Each node has access rights 600 on /root/.ssh/

### Database configuration

Various applications (Ambari, Hive, Oozie, Ranger) in the HDP stack require a
relational database. To ease maintenance it is recommended to use the same
database for all applications. This requires some non-standard configuration.
This document assumes a PostgreSQL database, other database systems are possible
though, check with the organisation what is preferred.

* [ ] A node is assigned for running the database
* [ ] The database node has either PostgreSQL 9.1.13+ or 9.3
* [ ] Non-default databases are created
    * [ ] Ambari - http://docs.hortonworks.com/HDPDocuments/Ambari-2.2.1.0/bk_ambari_reference_guide/content/_using_ambari_with_postgresql.html
    * [ ] Hive - http://docs.hortonworks.com/HDPDocuments/Ambari-2.2.1.0/bk_ambari_reference_guide/content/_using_hive_with_postgresql.html
    * [ ] Oozie - http://docs.hortonworks.com/HDPDocuments/Ambari-2.2.1.0/bk_ambari_reference_guide/content/_using_oozie_with_postgresql.html
    * [ ] Ranger - https://docs.hortonworks.com/HDPDocuments/HDP2/HDP-2.4.0/bk_Security_Guide/content/configuring_postgresql_for_ranger.html
* [ ] Verify configuration of /var/lib/pgsql/9.3/data/pg_hba.conf
    * [ ] TYPE DATABASE     USER                ADDRESS  METHOD
    * [ ] host ambaridb     ambari              10.0.0.2 md5
    * [ ] host hivedb       hive                10.0.0.2 md5
    * [ ] host ooziedb      oozie               10.0.0.2 md5
    * [ ] host rangerdb     ranger              10.0.0.2 md5
    * [ ] host ranger_audit ranger,rangerlogger 10.0.0.2 md5
    * [ ] Address is replaced by applicable IP-address for each service
    * [ ] Above database names match with actual created databases
    * [ ] Above user names match with actual created database users
* [ ] Verify configuration of /var/lib/psql/9.3/data/postgresql.conf
    * [ ] Change property: listen_addresses='*'
    * [ ]   Alternatively: listen_addresses='10.0.0.2 10.0.03'
* [ ] PostgreSQL is restarted after all required configuration changes are made

### Kerberos configuration
