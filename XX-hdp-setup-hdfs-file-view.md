# Setup HDFS file view

If Ambari Server is running as a non-root user, such as 'ambari', and you are planning on using Ambari Views, the following properties in Services > HDFS > Configs > Advanced core-site must be added:

hadoop.proxyuser.ambari.groups=*
hadoop.proxyuser.ambari.hosts=*

# Setup
