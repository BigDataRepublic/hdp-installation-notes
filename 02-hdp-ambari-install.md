# Steps to install HDP with Ambari

Based on the documentation at http://docs.hortonworks.com/HDPDocuments/Ambari-2.2.1.0/bk_Installing_HDP_AMB/content/index.html.

1. Walk through hdp-ambari-install-checklist.md

1. Connect to the management node

1. Become root

    ```
    $ sudo su -
    ```

1. Kick off Ambari setup

    ```
    root $ ambari-server setup
    * Customize user account for ambari-server daemon [y/n] (n)? y
      Enter user account for ambari-server daemon (root): ambari
      Adjusting ambari-server permissions and ownership...
      Checking firewall status...
      Checking JDK...
      [1] Oracle JDK 1.8 + Java Cryptography Extension (JCE) Policy Files 8
      [2] Oracle JDK 1.7 + Java Cryptography Extension (JCE) Policy Files 7
      [3] Custom JDK
      ==============================================================================
    * Enter choice (1): 1  
      To download the Oracle JDK and the Java Cryptography Extension (JCE) Policy Files you must accept the license terms found at http://www.oracle.com/technetwork/java/javase/terms/license/index.html and not accepting will cancel the Ambari Server setup and you must install the JDK and JCE files manually.
      Do you accept the Oracle Binary Code License Agreement [y/n] (y)? y
      Downloading JDK from http://public-repo-1.hortonworks.com/ARTIFACTS/jdk-8u60-linux-x64.tar.gz to /var/lib/ambari-server/resources/jdk-8u60-linux-x64.tar.gz
      jdk-8u60-linux-x64.tar.gz... 100% (172.8 MB of 172.8 MB)
      Successfully downloaded JDK distribution to /var/lib/ambari-server/resources/jdk-8u60-linux-x64.tar.gz
      Installing JDK to /usr/jdk64/
      Successfully installed JDK to /usr/jdk64/
      Downloading JCE Policy archive from http://public-repo-1.hortonworks.com/ARTIFACTS/jce_policy-8.zip to /var/lib/ambari-server/resources/jce_policy-8.zip
      Successfully downloaded JCE Policy archive to /var/lib/ambari-server/resources/jce_policy-8.zip
      Installing JCE policy...
      Completing setup...
      Configuring database...
    * Enter advanced database configuration [y/n] (n)? y
      Configuring database...
      ==============================================================================
      Choose one of the following options:
      [1] - PostgreSQL (Embedded)
      [2] - Oracle
      [3] - MySQL
      [4] - PostgreSQL
      [5] - Microsoft SQL Server (Tech Preview)
      [6] - SQL Anywhere
      ==============================================================================
    * Enter choice (1): 4
    * Hostname (localhost): mgmt1.bdr.nl
    * Port (5432): 5432
    * Database name (ambari): ambaridb
    * Postgres schema (ambari): ambari
    * Username (ambari): ambari
    * Enter Database Password (bigdata): ambari
    * Re-enter password: ambari
      Configuring ambari database...
      Configuring remote database connection properties...
      WARNING: Before starting Ambari Server, you must run the following DDL against the database to create the schema: /var/lib/ambari-server/resources/Ambari-DDL-Postgres-EMBEDDED-CREATE.sql
    * Proceed with configuring remote database connection properties [y/n] (y)? y
      Extracting system views...
      .ambari-admin-2.2.1.0.161.jar
      .....
      Adjusting ambari-server permissions and ownership...
      Ambari Server 'setup' completed successfully.
    ```

1. Start the ambari server

    ```
    $ ambari-server start
    ```
    
   if errors occur take a look at the startup log

    ```
    $ cat /var/log/ambari-server/ambari-server.out
    ```

1. Open the Ambari webinterface in a browser

    http://10.0.0.2:8080

    Login with user: `admin`, password `admin`

1. Launch the install wizzard

    * Give the cluster a name
    * Select the HDP 2.4 stack
    * Enter the list of hosts:

        ```
        mgmt1.bdr.nl
        en1.bdr.nl
        mn1.bdr.nl
        wn1.bdr.nl
        ```

    * Copy the private key, /root/.ssh/id_rsa, in the required field
    * Confirm hosts

        If registration fails, check if you can do an ssh, passwordless login,
        to the failing host from the host running ambari server.

        Make sure to resolve all issues that are brought up by the Host checks
        which are performed.

    * We go for a minimal installation, which we will gradually extend. Therefore
      only select the following services:

      * HDFS
      * YARN + MapReduce2
      * ZooKeeper
      * Ambari Metrics

    * Assign masters:

       * mgmt1: 
            * ZooKeeper Server
       * mn1: 
            * NameNode
            * History Server
            * App Timeline Server
            * ResourceManager
            * ZooKeeper Server
            * Metric Collector
        * wn1: 
            * SNameNode
            * ZooKeeper Server

    * Assign slaves and clients

        * mgmt1: 
            * NodeManager
            * Client
        * mn1: 
            * DataNode
            * Client
        * wn1: 
            * DataNode
            * NodeManager
            * Client
        * en1: 
            * NodeManager
            * Client

    * Customize services. For the minimal install we have chosen all configuration
      options should have been addresse properly by with recommended defaults.
      The only thing we need to address is the fact that we run ambari-server as
      ambari user and not as root.

      See: https://docs.hortonworks.com/HDPDocuments/Ambari-2.2.1.0/bk_Ambari_Security_Guide/content/_how_to_configure_ambari_server_for_non-root.html

      To this end we need to adapt the HDFS configuration:

      Add the following two properties to Custom core site:

        hadoop.proxyuser.ambari.groups=*
        hadoop.proxyuser.ambari.hosts=*

    * Review the final configuration and start deployment

If everything went without problems, we have now a minimal HDP which runs:

    * HDFS
    * MapReduce2
    * YARN
    * ZooKeeper

Monitoring the cluster is enabled by the ambari metric agents that run on the
hosts. The next step will be to configure NameNode High Availability (HA).

1. A first simple test to see if the cluster is up to it's job

    Log into the mgmt1 host with ssh and become the hdfs user.

    $ sudo su - hdfs

    Now write 100MB of random data to the cluster

    $ yarn jar /usr/hdp/current/hadoop-mapreduce-client/hadoop-mapreduce-examples.jar randomwriter -Dtest.randomwrite.total_bytes=10000000 test-after-upgrade

# Configuring NameNode HA

https://docs.hortonworks.com/HDPDocuments/Ambari-2.2.1.1/bk_Ambari_Users_Guide/content/_namenode_high_availability.html

1. Check to make sure you have at least three hosts in your cluster and are running at least three ZooKeeper servers.
1. Check to make sure that the HDFS and ZooKeeper services are not in Maintenance Mode.
1. In Ambari Web, select Services > HDFS > Summary.
1. Select Service Actions and choose Enable NameNode HA.
1, Enter a name for the Nameservice id: bdr-hadoop
1. Select hosts

      mgmt1: JournalNode
        mn1: NameNode, JournalNode
        wn1: Aditional NameNode
        en1: JournalNode

1. Create Checkpoints : Follow the instructions in the step. You need to log in
   to your current NameNode host to run the commands to put your NameNode into
   safe mode and create a checkpoint. When Ambari detects success, the message
   on the bottom of the window changes. Click Next.
1. Configure Components : The wizard configures your components, displaying
   progress bars to let you track the steps. Click Next to continue.
1. Initialize JournalNodes : Follow the instructions in the step. You need to
   login to your current NameNode host to run the command to initialize the
   JournalNodes. When Ambari detects success, the message on the bottom of the
   window changes. Click Next.
1. Start Components : The wizard starts the ZooKeeper servers and the NameNode,
   displaying progress bars to let you track the steps. Click Next to continue.
1. Initialize Metadata : Follow the instructions in the step. For this step you
   must log in to both the current NameNode and the additional NameNode. Make
   sure you are logged in to the correct host for each command. Click Next when
   you have completed the two commands. A Confirmation pop-up window displays,
   reminding you to do both steps. Click OK to confirm.
1. Finalize HA Setup : The wizard the setup, displaying progress bars to let you
   track the steps. Click Done to finish the wizard. After the Ambari Web GUI
   reloads, you may see some alert notifications. Wait a few minutes until the
   services come back up. If necessary, restart any components using Ambari Web.
1. Adjust the ZooKeeper Failover Controller retries setting for your environment.
   Browse to Services > HDFS > Configs >Advanced core-site. Set
   ha.failover-controller.active-standby-elector.zk.op.retries=120

# Configuring ResourceManager HA

https://docs.hortonworks.com/HDPDocuments/HDP2/HDP-2.4.0/bk_hadoop-ha/content/ch_HA-ResourceManager.html

In a typical deployment, ZooKeeper daemons are configured to run on three or
five nodes. It is, however, acceptable to co-locate the ZooKeeper nodes on the
same hardware as the HDFS NameNode and Standby Node. Many operators choose to
deploy the third ZooKeeper process on the same node as the YARN ResourceManager.
To achieve performance and improve isolation, Hortonworks recommends configuring
the ZooKeeper nodes such that the ZooKeeper data and HDFS metadata is stored on
separate disk drives.

1. Check to make sure you have at least three hosts in your cluster and are running at least three ZooKeeper servers.
1. In Ambari Web, select Dashboard -> Actions -> Stop all
1. In Ambari Web, select Services > YARN > Summary.
1. Select Service Actions and choose Enable ResourceManager HA.
1. Get Started -> click next
1. Select Host -> Set mgmt1.bdr.nl as additional ResourceManager, click Next
1. Review changes -> click next
1. Configure components
