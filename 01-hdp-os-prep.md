**NOTE:** Instructions based on CentOS6, adapt to RHEL6 where needed.

# Host mgmt

1. Become root

    $ su -

1. Make sure our system is up to data and has the correct java installed

    $ yum update

1. Configure timezone and ntpd

    $ yum install ntp
    $ mv /etc/localtime /etc/localtime.bkp
    $ cp /usr/share/zoneinfo/Europe/Amsterdam /etc/localtime
    $ chkconfig ntpd on
    $ service ntpd start

1. Make sure that the hostname is set to the FQDN

    $ hostname
    mgmt1.bdr.nl

1. Edit /etc/hosts so that all nodes involved in the HDP can be found by FQDN

    $ vim /etc/hosts

    $ echo "10.0.0.2    mgmt1.bdr.nl mgmt1 localhost
    10.0.0.3    en1.bdr.nl en1
    10.0.0.4    mn1.bdr.nl mn1
    10.0.0.5    wn1.bdr.nl wn1" > /etc/hosts

1. Disable IPv6

    $ vim /etc/sysctl.conf

    # Disable IPv6
    net.ipv6.conf.all.disable_ipv6 = 1
    net.ipv6.conf.default.disable_ipv6 = 1

    $ echo 1 > /proc/sys/net/ipv6/conf/all/disable_ipv6
    $ echo 1 > /proc/sys/net/ipv6/conf/default/disable_ipv6

1. Stop iptables

    $ chkconfig iptables off
    $ service iptables stop

1. Edit /etc/sysconfig/network to use the proper FQDN for the HOSTNAME property
   https://docs.hortonworks.com/HDPDocuments/Ambari-2.2.1.0/bk_Installing_HDP_AMB/content/_edit_the_network_configuration_file.html

1. Setup password-less login with SSH

    $ ssh-keygen
    $ cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys
    $ scp ~/.ssh/id_rsa.pub vagrant@en1.bdr.nl:/home/vagrant/mgmt_id_rsa.pub
    $ scp ~/.ssh/id_rsa.pub vagrant@mn1.bdr.nl:/home/vagrant/mgmt_id_rsa.pub
    $ scp ~/.ssh/id_rsa.pub vagrant@wn1.bdr.nl:/home/vagrant/mgmt_id_rsa.pub

    On each host:
    $ cat /home/vagrant/mgmt_id_rsa.pub >> /root/.ssh/authorized_keys

1. Setup dedicated kerberos server

   https://docs.hortonworks.com/HDPDocuments/HDP2/HDP-2.4.0/bk_Security_Guide/content/_optional_install_a_new_mit_kdc.html

    $ yum install krb5-server krb5-libs krb5-workstation
    $ vim /etc/krb5.conf

    [logging]
     default = FILE:/var/log/krb5libs.log
     kdc = FILE:/var/log/krb5kdc.log
     admin_server = FILE:/var/log/kadmind.log

    [libdefaults]
     default_realm = HDP.BDR.NL
     dns_lookup_realm = false
     dns_lookup_kdc = false
     ticket_lifetime = 24h
     renew_lifetime = 7d
     forwardable = true

    [realms]
     HDP.BDR.NL = {
      kdc = mgmt1.bdr.nl
      admin_server = mgmt1.bdr.nl
     }

    [domain_realm]
     .hdp.bdr.nl = HDP.BDR.NL
     hdp.bdr.nl = HDP.BDR.NL


    $ kdb5_util create -s [Pass: kerberos.bdr.nl]
    $ chkconfig krb5kdc on
    $ chkconfig kadmin on
    $ service krb5kdc start
    $ service kadmin start

    $ kadmin.local -q "addprinc admin/admin" [Pass: admin]
    $ vim /var/kerberos/krb5kdc/kadm5.acl

   Make sure that the REALM part is set to HDP.BDR.NL

    $ service kadmin restart


1. a. Install PostgreSQL 9.3 (https://wiki.postgresql.org/wiki/YUM_Installation)

      $ vim /etc/yum.repos.d/CentOS-Base.repo

      Add line: `exclude=postgresql*` to base and updates section

      $ yum localinstall https://download.postgresql.org/pub/repos/yum/9.3/redhat/rhel-6-x86_64/pgdg-centos93-9.3-2.noarch.rpm
      $ yum list postgresql*
      $ yum install postgresql93-server
      $ service postgresql-9.3 initdb
      $ chkconfig postgresql-9.3 on
      $ service postgresql-9.3 start


   b. Prepare Postgres databases for HDP

        database name | user name  | password
        --------------+------------+------------
        ambaridb      | ambari     | ambari
        hivedb        | hive       | hive
        ooziedb       | oozie      | oozie
        rangerdb      | ranger     | ranger

        $ -u postgres psql
        postgres=# CREATE DATABASE ambaridb;
        postgres=# CREATE USER ambari WITH PASSWORD 'ambari';
        postgres=# GRANT ALL PRIVILEGES ON DATABASE ambaridb TO ambari;

        postgres=# \connect ambaridb;
        postgres=# CREATE SCHEMA ambari AUTHORIZATION ambari;
        postgres=# ALTER SCHEMA ambari OWNER TO ambari;
        postgres=# ALTER ROLE ambari SET search_path to ‘ambari’, 'public';

        postgres=# \c postgres postgres
        postgres=# CREATE DATABASE hivedb;
        postgres=# CREATE USER hive WITH PASSWORD 'hive';
        postgres=# GRANT ALL PRIVILEGES ON DATABASE hivedb TO hive;

        postgres=# CREATE DATABASE ooziedb;
        postgres=# CREATE USER oozie WITH PASSWORD 'oozie';
        postgres=# GRANT ALL PRIVILEGES ON DATABASE ooziedb TO oozie;

        postgres=# CREATE DATABASE rangerdb;
        postgres=# CREATE USER ranger WITH PASSWORD 'ranger';
        postgres=# GRANT ALL PRIVILEGES ON DATABASE rangerdb TO ranger;

        postgres=# \q

        $ psql -U ambari -d ambaridb
        postgres=# \connect ambari
        postgres=# \i /var/lib/ambari-server/resources/Ambari-DDL-Postgres-CREATE.sql

   c. Make sure password access of postgres is possible

    * Change password authentication:
      http://stackoverflow.com/questions/18664074/getting-error-peer-authentication-failed-for-user-postgres-when-trying-to-ge
    * Create proper tables and roles
      https://docs.hortonworks.com/HDPDocuments/Ambari-2.1.2.1/bk_ambari_reference_guide/content/_using_ambari_with_postgresql.html
    * Make sure the database can be accessed over tcp/ip
      http://www.cyberciti.biz/tips/postgres-allow-remote-access-tcp-connection.html

      $ vim /var/lib/pgsql/9.3/data/pg_hba.conf

      host  hivedb  hive  10.0.0.3/0 md5
      host  ooziedb oozie 10.0.0.3/0 md5

   d. Make sure Ambari knows how to talk PostgreSQL

    $ yum install postgresql-jdbc
    $ ambari-server setup --jdbc-db=postgres --jdbc-driver=/usr/share/java/postgresql-jdbc.jar

# other

1. yum update

2. yum install java-1.8.0-openjdk

3. Edit /etc/hosts so that all nodes involved in the HDP can be found by FQDN

4. Add mgmt1 public key to authorized keys (depends on #mgmt1.5)

    $ mkdir ~/.ssh
    $ touch ~/.ssh/authorized_keys
    $ chmod 600 -R ~/.ssh
    $ cat id_rsa.pub >> ~/.ssh/authorized_keys

5. Make sure that the hostname is set to the FQDN

    $ hostname en1.bdr.nl

6. Edit /etc/sysconfig/network to use the proper FQDN for the HOSTNAME properrt

7. Install and start ntpd

    $ yum install ntp
    $ chkconfig ntpd on
    $ service ntpd start

8. Stop iptables

    $ chkconfig iptables off
    $ /etc/init.d/iptables stop
