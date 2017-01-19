# Setting up a cluster with Blueprints

**Goal:** Automate the rollout of an Ambari managed cluster using blueprints.

If you set up multiple clusters

## Get blueprint for current cluster
curl -H "X-Requested-By: ambari" -X GET -u admin:admin http://10.0.0.3:8080/api/v1/clusters/HDP_DEV_TUTORIAL?format=blueprint > hdp_dev_tutorial_bp.json

## Register blueprint

curl -u admin:admin -i -H 'X-Requested-By: ambari' -X POST -d @conf/hdp_dev_tutorial_bp.json http://10.0.0.3:8080/api/v1/blueprints/hdp_dev_tutorial_topology

## Create cluster

curl -u admin:admin -i -H 'X-Requested-By: ambari' -X POST -d @conf/hdp_dev_tutorial_cc.json  $AMBARI_API
