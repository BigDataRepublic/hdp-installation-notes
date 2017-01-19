# Get started

# Select stack

# Install Options

# Confirm Host

# Choose services:

* HDFS
* YARN
* Tez
* Hive
* Pig
* Zookeeper
* Ambari Metrics
* Spark

# Assign Masters

* SNameNode - mn2.bdr.nl
* NameNode - mn1.bdr.nl
* History Server - en.bdr.nl (https://hadoop.apache.org/docs/r2.4.1/hadoop-yarn/hadoop-yarn-site/HistoryServerRest.html)
* Timeline Server - en.bdr.nl (https://docs.hortonworks.com/HDPDocuments/HDP2/HDP-2.4.2/bk_yarn_resource_mgt/content/ch_timeline_server.html)
* Resource Manager - en.bdr.nl (https://hadoop.apache.org/docs/r2.4.1/hadoop-yarn/hadoop-yarn-site/ResourceManagerRest.html)
* Hive MetaStore - mn1.bdr.nl (http://www.cloudera.com/documentation/archive/cdh/4-x/4-2-0/CDH4-Installation-Guide/cdh4ig_topic_18_4.html)
* HiveServer2 - en.bdr.nl
* ZooKeeper Server - mn1,bdr.nl
* ZooKeeper Server - mn2,bdr.nl
* ZooKeeper Server - wn1,bdr.nl
* Spark History Server - en.bdr.nl (http://spark.apache.org/docs/latest/monitoring.html)
* Grafana - en.bdr.nl
* Metrics Collector - en.bdr.nl

# Assign Slaves and Clients

* Data nodes: mn1, mn2, wn1
* Node manager: mn1, mn2, wn1
* client: en

# Customize services

* Enter postgres details for hive:

  - database host: en.bdr.nl
  - datbase name: hivedb
  - database username: hive
  - database password: hive
  - Hive database type: postgres

* Pick a password for grafana

# Review

# Install start and test
