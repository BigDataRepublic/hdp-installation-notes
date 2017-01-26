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

First we will install and run the ntp deamon: A Network Time Protocol daemon. This protocol is the most common method to synchronize the software clock of a GNU/Linux system with internet time servers. It is designed to ensure that all nodes on your clusters have the same idea about what time and day it is.

    ```
    $ yum install ntp
    ```
Now that the service is installed we will setup the desired timezone and date settings. We will backup the current settings and use the Amsterdam timezone as the new settings. After we have set the settings the ntpd deamon will be started.
    
    ```
    $ mv /etc/localtime /etc/localtime.bkp
    $ cp /usr/share/zoneinfo/Europe/Amsterdam /etc/localtime
    $ chkconfig ntpd on
    $ service ntpd start
    ```

1. Disable Transparant Huge Pages

Transparant Huge Pages (THP) are a setting in Linux that enable a flexible memory block size. The standard size of a memory block is 4kb but with THP you can increase the blocks to 256MB. However, in memory databases benifit of small memory blocks because they know which blocks contains which data but they do not know where in the block this exact data lies. This means that the database would rather look through 4kb of data than through 256mb of data.
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
1. Edit /etc/hosts so that all nodes involved in the HDP can be found through its Fully Qualified Domain Name (FQDN)
```
	vim /etc/hosts

	The content of the file should be:

    10.0.0.2 mgmt1.bdr.nl mgmt1 localhost
	10.0.0.3 en1.bdr.nl en1
	10.0.0.4 mn1.bdr.nl mn1
	10.0.0.5 wn1.bdr.nl wn1

	127.0.0.1 localhost localhost.localdomain localhost4 localhost4.localdomain4
	::1         localhost localhost.localdomain localhost6 localhost6.localdomain6
```
   **NOTE:** For each host add localhost to the right line!
1. Edit /etc/sysconfig/network to use the proper FQDN for the HOSTNAME property

1. Disable IPv6 because Hadoop does not fully support IPv6 as of yet
```
    $ vim /etc/sysctl.conf
```
Paste or write the following in the bottom of the file and close it
```
    # Disable IPv6
    net.ipv6.conf.all.disable_ipv6 = 1
    net.ipv6.conf.default.disable_ipv6 = 1
```
```
    $ echo 1 > /proc/sys/net/ipv6/conf/all/disable_ipv6
    $ echo 1 > /proc/sys/net/ipv6/conf/default/disable_ipv6
```
1. Stop iptables because you do not want to bother with firewalling while you are setting up the cluster
```
    $ chkconfig iptables off
    $ service iptables stop
```
1. Make sure that the hostname is set to the FQDN and that it matches with the
   name(s) in /etc/hosts
```
    $ hostname
```
# ALERT ALERT DO ONLY ON Host mgmt1.bdr.nl

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
1. Setup password-less login with SSH by copying the public key to all the nodes.
```
    $ ssh-keygen (Press enter for every question)
    $ cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys
    $ scp ~/.ssh/id_rsa.pub vagrant@en1.bdr.nl:/home/vagrant/mgmt_id_rsa.pub
    $ scp ~/.ssh/id_rsa.pub vagrant@mn1.bdr.nl:/home/vagrant/mgmt_id_rsa.pub
    $ scp ~/.ssh/id_rsa.pub vagrant@wn1.bdr.nl:/home/vagrant/mgmt_id_rsa.pub
    $ rsync -a --relative .ssh/authorized_keys en1
    $ rsync -a --relative .ssh/authorized_keys mn1
    $ rsync -a --relative .ssh/authorized_keys wn1
```

# Installating Ambari and PostgreSQL on the management node

1. Install Ambari
```
    $ wget -nv http://public-repo-1.hortonworks.com/ambari/centos6/2.x/updates/2.2.1.0/ambari.repo -O /etc/yum.repos.d/ambari.repo
    $ yum install ambari-server
```

1. Install PostgreSQL 9.3 (https://wiki.postgresql.org/wiki/YUM_Installation)
```
      $ vim /etc/yum.repos.d/CentOS-Base.repo
```

1. We will introduce a new repository for postgresql because it provides a newer version than the standard. For this to be effective we first need to disable postgresql in the standard repository.
```
    Add line: `exclude=postgresql*` to base and updates section
```
```
      $ yum localinstall https://download.postgresql.org/pub/repos/yum/9.3/redhat/rhel-6-x86_64/pgdg-centos93-9.3-2.noarch.rpm
      $ yum install postgresql93-server
      $ service postgresql-9.3 initdb
      $ chkconfig postgresql-9.3 on
      $ service postgresql-9.3 start
```
    [MICHEL: deze punten weglaten?]
    Make sure password access of postgres is possible
    Change password authentication [info](http://stackoverflow.com/questions/18664074/getting-error-peer-authentication-failed-for-user-postgres-when-trying-to-ge)
    Create proper tables and roles [info](https://docs.hortonworks.com/HDPDocuments/Ambari-2.1.2.1/bk_ambari_reference_guide/content/_using_ambari_with_postgresql.html)
    Make sure the database can be accessed over tcp/ip [info](http://www.cyberciti.biz/tips/postgres-allow-remote-access-tcp-connection.html)
```
      root $ su - postgres
      postgres $ vim /var/lib/pgsql/9.3/data/pg_hba.conf
```
Change the existing users for "local", "IPv4" and "IPv6" from *all* to *postgres* and add the following lines to the file:
```
      host  ambaridb ambari             10.0.0.2/32 md5
      host  rangerdb ranger,rangeraudit 10.0.0.2/32 md5
      host  hivedb   hive               10.0.0.3/32 md5
      host  ooziedb  oozie              10.0.0.3/32 md5
```
```
      postgres $ vim /var/lib/pgsql/9.3/data/postgresql.conf
```
Uncomment the following line and change the value:
```
      listen_addresses = '*'
```
```
      postgres $ exit
      root $ service postgresql-9.3 restart
```

1. Prepare Postgres databases for HDP.
We will setup the following databases:
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
    ambaridb=# CREATE SCHEMA ambari AUTHORIZATION ambari;
    ambaridb=# ALTER SCHEMA ambari OWNER TO ambari;
    ambaridb=# ALTER ROLE ambari SET search_path to ‘ambari’, 'public';
```
```
    ambaridb=# \c postgres postgres
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
        $ psql -U ambari -d ambaridb (Password = ambari)
        ambaridb=# \i /var/lib/ambari-server/resources/Ambari-DDL-Postgres-CREATE.sql
        ambaridb=# \q
```

1. Make sure Ambari knows how to talk PostgreSQL
We will install a driver to connect from ambari to postgres and then connect to postgres using this driver.
```
    $ yum install postgresql-jdbc
    $ ambari-server setup --jdbc-db=postgres --jdbc-driver=/usr/share/java/postgresql-jdbc.jar
```

1. Create a dedicated user for running ambari
```
    $ groupadd hadoop
    $ useradd -G hadoop ambari
```
