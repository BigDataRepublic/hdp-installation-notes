# Intro

This document describes some basic Kerberos commands in the context of HDP
Kerberized installations. At this point it is not ment as an extensive Kerberos
guide. It does **not** describe best practices (yet) for a fool-proof Kerberos
installation, but helps one to get around a bit when a Kerberized HDP installation
is required.

# Setup dedicated kerberos server

https://docs.hortonworks.com/HDPDocuments/HDP2/HDP-2.4.0/bk_Security_Guide/content/_optional_install_a_new_mit_kdc.html

    $ sudo su -
    $ yum install krb5-server krb5-libs krb5-workstation
    $ vim /etc/krb5.conf


Content of krb5.conf for a simple configuration must look somewhat like below.
Note: talk to identity management experts in the organization to for best
practices within the organization, and for setting up thrust relations with
production servers (either Active Directory or other Kerberos enabled servers).

´´´
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
´´´

    $ kdb5_util create -s [Pass: kerberos.bdr.nl]
    $ chkconfig krb5kdc on
    $ chkconfig kadmin on
    $ service krb5kdc start
    $ service kadmin start

    $ kadmin.local -q "addprinc admin/admin" [Pass: admin]
    $ vim /var/kerberos/krb5kdc/kadm5.acl

      Make sure that the REALM part is set to HDP.BDR.NL

    $ sudo service kadmin restart

# List available principals

$ kadmin -p admin@HDP.BDR.NL

    kadmin: listprincs
    kadmin: exit

# Adding a new principal as admin

$ kadmin -p admin@HDP.BDR.NL
    kadmin: addprinc hdfs@HDP.BDR.NL
    #You will be asked for a password
    kadmin: exit

# Obtaining a ticket for the hdfs user

$ kinit hdfs@HDP.BDR.NL
$ kinit -p hdfs
$ hadoop fs -mkdir /user/admin
$ hadoop fs -chown admin /user/admin

#
