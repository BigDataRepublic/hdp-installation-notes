# Configuring High Availability

In this session we will improve the availability of our fresh cluster by configuring High Availability for the namenode and for the resource manager. This means that after these steps, both HDFS and YARN will be more tollerant to system failure. If one of the master nodes falls out, the other will take over.

# Configuring NameNode HA

https://docs.hortonworks.com/HDPDocuments/Ambari-2.2.1.1/bk_Ambari_Users_Guide/content/_namenode_high_availability.html

1. Check to make sure you have at least three hosts in your cluster and are running at least three ZooKeeper servers.
1. Check to make sure that the HDFS and ZooKeeper services are not in Maintenance Mode.
1. In Ambari Web, select *Services* > *HDFS* > *Summary*.
1. Select Service Actions and choose *Enable NameNode HA*.
1. Enter a name for the Nameservice id: `bdr-hadoop`
1. Select hosts
    * mgmt1: JournalNode
    * mn1: NameNode, JournalNode
    * wn1: Aditional NameNode
    * en1: JournalNode

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
1. In Ambari Web, select *Dashboard* -> *Actions* -> *Stop all*
1. In Ambari Web, select *Services* > *YARN* > *Summary*.
1. Select *Service Actions* and choose *Enable ResourceManager HA*.
1. Get Started -> click next
1. Select Host -> Set mgmt1.bdr.nl as additional ResourceManager, click Next
1. Review changes -> click next
1. Configure components
