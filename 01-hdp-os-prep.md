**NOTE:** Instructions based on CentOS6, adapt to RHEL6 where needed.

# All hosts

1. Become root
```
    $ su -
```
1. Make sure our system is up to date
```
    $ yum update
```
1. Configure timezone and ntpd
```
    $ yum install ntp
    $ mv /etc/localtime /etc/localtime.bkp
    $ cp /usr/share/zoneinfo/Europe/Amsterdam /etc/localtime
    $ chkconfig ntpd on
    $ service ntpd start
```
1. Disable Transparant Huge Pages
```
    $ vim /etc/rc.local
```
```
    # disable THP at boot time
    if test -f /sys/kernel/mm/transparent_hugepage/enabled; then
      echo never > /sys/kernel/mm/redhat_transparent_hugepage/enabled
    fi
    if test -f /sys/kernel/mm/transparent_hugepage/defrag;
      then echo never > /sys/kernel/mm/redhat_transparent_hugepage/defrag
    fi
```
```
    $ sh /etc/rc.local
```
1. Edit /etc/hosts so that all nodes involved in the HDP can be found by FQDN
```
    $ echo "10.0.0.2    mgmt1.bdr.nl mgmt1 localhost
    10.0.0.3    en1.bdr.nl en1
    10.0.0.4    mn1.bdr.nl mn1
    10.0.0.5    wn1.bdr.nl wn1" > /etc/hosts
```
   **NOTE:** For each host add localhost to the right line!
1. Edit /etc/sysconfig/network to use the proper FQDN for the HOSTNAME property

1. Disable IPv6
```
    $ vim /etc/sysctl.conf
```
```
    # Disable IPv6
    net.ipv6.conf.all.disable_ipv6 = 1
    net.ipv6.conf.default.disable_ipv6 = 1
```
```
    $ echo 1 > /proc/sys/net/ipv6/conf/all/disable_ipv6
    $ echo 1 > /proc/sys/net/ipv6/conf/default/disable_ipv6
```
1. Stop iptables
```
    $ chkconfig iptables off
    $ service iptables stop
```
1. Make sure that the hostname is set to the FQDN and that it matches with the
   name(s) in /etc/hosts
```
    $ hostname
```
# Host mgmt

1. Become root
```
    $ su -
```
1. Install wget
```
    $ yum install wget
```
1. Make sure that the hostname is set to the FQDN
```
    $ hostname
    mgmt1.bdr.nl
```
1. Setup password-less login with SSH
```
    $ ssh-keygen
    $ cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys
    $ scp ~/.ssh/id_rsa.pub vagrant@en1.bdr.nl:/home/vagrant/mgmt_id_rsa.pub
    $ scp ~/.ssh/id_rsa.pub vagrant@mn1.bdr.nl:/home/vagrant/mgmt_id_rsa.pub
    $ scp ~/.ssh/id_rsa.pub vagrant@wn1.bdr.nl:/home/vagrant/mgmt_id_rsa.pub
```

1. Don't forget to enable ssh keyless login from the mgmt host to itself.
   Add mgmt1 public key to authorized keys.
```
    $ mkdir ~/.ssh
    $ touch ~/.ssh/authorized_keys
    $ chmod 600 -R ~/.ssh
    $ cat id_rsa.pub >> ~/.ssh/authorized_keys
```
    On each host:
```
    $ cat /home/vagrant/mgmt_id_rsa.pub >> /root/.ssh/authorized_keys
```
1. Install Ambari
```
    $ wget -nv http://public-repo-1.hortonworks.com/ambari/centos6/2.x/updates/2.2.1.0/ambari.repo -O /etc/yum.repos.d/ambari.repo
    $ yum install ambari-server
```
1.  Installing and  configure PostgreSQL
    1. Install PostgreSQL 9.3 (https://wiki.postgresql.org/wiki/YUM_Installation)
```
      $ vim /etc/yum.repos.d/CentOS-Base.repo
```
    1. Add line: `exclude=postgresql*` to base and updates section
```
      $ yum localinstall https://download.postgresql.org/pub/repos/yum/9.3/redhat/rhel-6-x86_64/pgdg-centos93-9.3-2.noarch.rpm
      $ yum list postgresql*
      $ yum install postgresql93-server
      $ service postgresql-9.3 initdb
      $ chkconfig postgresql-9.3 on
      $ service postgresql-9.3 start
```
    1. Make sure password access of postgres is possible

    1. Change password authentication [info](http://stackoverflow.com/questions/18664074/getting-error-peer-authentication-failed-for-user-postgres-when-trying-to-ge)
    1. Create proper tables and roles [info](https://docs.hortonworks.com/HDPDocuments/Ambari-2.1.2.1/bk_ambari_reference_guide/content/_using_ambari_with_postgresql.html)
    1. Make sure the database can be accessed over tcp/ip [info](http://www.cyberciti.biz/tips/postgres-allow-remote-access-tcp-connection.html)
```
      root $ su - postgres
      postgres $ vim /var/lib/pgsql/9.3/data/pg_hba.conf
```
```
      local ambaridb ambari                         md5
      host  rangerdb ranger,rangeraudit 10.0.0.2/32 md5
      host  hivedb   hive               10.0.0.3/32 md5
      host  ooziedb  oozie              10.0.0.3/32 md5
```
```
      postgres $ vim /var/lib/pgsql/9.3/data/postgresql.conf
```
```
      listen_addresses = '*'
```
```
      postgres $ exit
      root $ service postgresql-9.3 restart
```

    1. Prepare Postgres databases for HDP
```
        database name | user name  | password
        --------------+------------+------------
        ambaridb      | ambari     | ambari
        hivedb        | hive       | hive
        ooziedb       | oozie      | oozie
        rangerdb      | ranger     | ranger
```
```
        $ sudo su - postgres
        $ psql
```
```
    postgres=# CREATE DATABASE ambaridb;
    postgres=# CREATE USER ambari WITH PASSWORD 'ambari';
    postgres=# GRANT ALL PRIVILEGES ON DATABASE ambaridb TO ambari;
```
```
    postgres=# \connect ambaridb;
    postgres=# CREATE SCHEMA ambari AUTHORIZATION ambari;
    postgres=# ALTER SCHEMA ambari OWNER TO ambari;
    postgres=# ALTER ROLE ambari SET search_path to ‘ambari’, 'public';
```
```
    postgres=# \c postgres postgres
    postgres=# CREATE DATABASE hivedb;
    postgres=# CREATE USER hive WITH PASSWORD 'hive';
    postgres=# GRANT ALL PRIVILEGES ON DATABASE hivedb TO hive;
```
```
    postgres=# CREATE DATABASE ooziedb;
    postgres=# CREATE USER oozie WITH PASSWORD 'oozie';
    postgres=# GRANT ALL PRIVILEGES ON DATABASE ooziedb TO oozie;
```
```
    postgres=# CREATE DATABASE rangerdb;
    postgres=# CREATE USER ranger WITH PASSWORD 'ranger';
    postgres=# GRANT ALL PRIVILEGES ON DATABASE rangerdb TO ranger;
    postgres=# \q
```
```
        $ psql -U ambari -d ambaridb
        postgres=# \i /var/lib/ambari-server/resources/Ambari-DDL-Postgres-CREATE.sql
        postgres=# \q
```
    1. Make sure Ambari knows how to talk PostgreSQL
```
    $ yum install postgresql-jdbc
    $ ambari-server setup --jdbc-db=postgres --jdbc-driver=/usr/share/java/postgresql-jdbc.jar
```
1. Create a dedicated user for running ambari
```
    $ groupadd hadoop
    $ useradd -G hadoop ambari
```
