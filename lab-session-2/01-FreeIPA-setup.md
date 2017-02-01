# Setup a FreeIPA server.

#### External resources

* [Setup LDAP IPA](https://github.com/abajwa-hw/security-workshops/blob/master/Setup-LDAP-IPA.md)
* [Setup Kerberos IPA](https://github.com/abajwa-hw/security-workshops/blob/master/Setup-kerberos-IPA-23.md)

#### Introduction

Although this is likely not part of the typical HDP setup, integrating with an
existing Active Directory or an alternative such as FreeIPA, is likely. Therefore
we setup a FreeIPA server which we can use as both Kerberos authentication server
and LDAP server for our Data Platform.

**NOTE:** Because some of the FreeIPA dependency packages clash with some
of the HDP packages so we have to setup a dedicated VM for FreeIPA.

#### Goal

The goal is not to setup a fully configured and secure identity
management server. We just want a setup which we can use to integrate our data
platform with. For a secure installation of Active Directory or FreeIPA refer to
identity management experts within the organisation.

#### Install and configure IPA

1. Log in with ssh to ipa.bdr.nl
1. Become root
```
    vagrant@ipa $ sudo su -
```
1. Update system
```
    root@ipa $ yum update
```
1. Configure /etc/hosts
```
    root@ipa $ vim /etc/hosts
```
```
    10.0.0.2    mgmt1.bdr.nl mgmt1
    10.0.0.3    en1.bdr.nl en1
    10.0.0.4    mn1.bdr.nl mn1
    10.0.0.5    wn1.bdr.nl wn1 localhost
    10.0.0.6    ipa.bdr.nl ipa

    127.0.0.1   localhost localhost.localdomain localhost4 localhost4.localdomain4
    ::1         localhost localhost.localdomain localhost6 localhost6.localdomain6
```
Make sure that the last two lines do not contain a reference to ipa.bdr.nl. Pinging
this domain name should always result in a ping to the proper IP-address and not
to 127.0.0.1.
1. Install ipa-server
```
    root@ipa $ yum install ipa-server
```
1. Configure the ipa server
```
    root@ipa $ ipa-server-install
    Server host name [ipa.bdr.nl]: <enter>
    Please confirm the domain name [bdr.nl]: <enter>
    Please provide a realm name [BDR.NL]: <enter>
    Directory Manager password: bdr-ipa-admin<enter>
    IPA admin password: bdr-ipa-admin<enter>
    Continue to configure the system with these values? [no]: yes<enter>
```
1. Configure user and group identities

    First obtain a Kerberos ticket to adminstrate users in IPA
```
    root@ipa $ kinit admin
    root@ipa $ Password for admin@BDR.NL:
```
    Next add some users and groups
```
    root@ipa $ ipa group-add marketing --desc marketing
    root@ipa $ ipa group-add hr --desc hr

    root@ipa $ ipa user-add  meting --first=Mark --last=Eting
    root@ipa $ ipa user-add  mting --first=Marke --last=Ting
    root@ipa $ ipa user-add  hanresource --first=Hum --last=Anresource

    root@ipa $ ipa group-add-member marketing --users=meting,mting
    root@ipa $ ipa group-add-member hr --users=hanresource

    # These admin accounts are required(?)
    root@ipa $ ipa user-add xapolicymgr --first=XAPolicy --last=Manager
    root@ipa $ ipa user-add rangeradmin --first=Ranger --last=Admin
    root@ipa $ ipa group-add-member admins --users=xapolicymgr,rangeradmin

    #Set passwords for accounts: bdr-ipa-account
    root@ipa $ echo bdr-ipa-account >> tmp.txt
    root@ipa $ ipa passwd meting < tmp.txt
    root@ipa $ ipa passwd mting < tmp.txt
    root@ipa $ ipa passwd hanresource < tmp.txt
    root@ipa $ ipa passwd xapolicymgr < tmp.txt
    root@ipa $ ipa passwd rangeradmin < tmp.txt
```

    Point a browser to https://ipa.bdr.nl/ipa/ui/ to verify the users
    and groups.

1. Now we need to tell ipa about the other hosts in our cluster. First let's find
   host which are not known yet.
```
    root@ipa $ awk -F" " '/10.0.0./ {print "echo Host: " $2 ";ipa host-find "$2}' /etc/hosts > ipa-host-find.sh
    root@ipa $ sh ipa-host-find.sh
    ...
    Host: en1.bdr.nl
    ---------------
    0 hosts matched
    ---------------
    ----------------------------
    Number of entries returned 0
    ----------------------------
    ...
```
    Look for hosts that do not return any matches.

1. For each host (mgmt1, en1,mn1,wn1) that did not return a match: Install ipa
   client and ldap clients on mgmt1
```
    $ ssh mgmt1
    vagrant@mgmt1 $ sudo su -
    root@mgmt1 $ yum install ipa-client openldap-clients
    root@mgmt1 $ ipa-client-install --domain=bdr.nl --server=ipa.bdr.nl --mkhomedir -p admin@BDR.NL -W
    Hostname: mgmt1.bdr.nl
    Realm: BDR.NL
    DNS Domain: bdr.nl
    IPA Server: ipa.bdr.nl
    BaseDN: dc=bdr,dc=nl

    Continue to configure the system with these values? [no]: yes
    Synchronizing time with KDC...
    Unable to sync time with IPA NTP server, assuming the time is in sync. Please check that 123 UDP port is opened.
    Password for admin@BDR.NL:
    Successfully retrieved CA cert
        Subject:     CN=Certificate Authority,O=BDR.NL
        Issuer:      CN=Certificate Authority,O=BDR.NL
        Valid From:  Wed May 04 13:26:31 2016 UTC
        Valid Until: Sun May 04 13:26:31 2036 UTC

    Enrolled in IPA realm BDR.NL
    Attempting to get host TGT...
    Created /etc/ipa/default.conf
    New SSSD config will be created
    Configured sudoers in /etc/nsswitch.conf
    Configured /etc/sssd/sssd.conf
    Configured /etc/krb5.conf for IPA realm BDR.NL
    trying https://ipa.bdr.nl/ipa/xml
    Forwarding 'env' to server u'https://ipa.bdr.nl/ipa/xml'
    Hostname (mgmt1.bdr.nl) not found in DNS
    Failed to update DNS records.
    Adding SSH public key from /etc/ssh/ssh_host_dsa_key.pub
    Adding SSH public key from /etc/ssh/ssh_host_rsa_key.pub
    Forwarding 'host_mod' to server u'https://ipa.bdr.nl/ipa/xml'
    Could not update DNS SSHFP records.
    SSSD enabled
    Configuring bdr.nl as NIS domain
    Configured /etc/openldap/ldap.conf
    NTP enabled
    Configured /etc/ssh/ssh_config
    Configured /etc/ssh/sshd_config
    Client configuration complete.
```

1. Check if the ldap search functionality is working correctly,
```
    root@mgmt1 $ ldapsearch -h ipa.bdr.nl:389 -D 'uid=admin,cn=users,cn=accounts,dc=bdr,dc=nl' -w bdr-ipa-admin -x -b 'dc=bdr,dc=nl' uid=mting
    root@mgmt1 $ id mting
    uid=996000005(mting) gid=996000005(mting) groups=996000005(mting),996000001(marketing)
    root@mgmt1 $ groups mting
    mting : mting marketing
```

1. Verify /var/kerberos/krb5kdc/kadm5.acl. Make sure that it has the proper
   REALM for the admin user.
```
    root@ipa $ vim /var/kerberos/krb5kdc/kadm5.acl
```
Change
```
*/admin@EXAMPLE.COM     *
```
To
```
*/admin@BDR.NL     *
```
