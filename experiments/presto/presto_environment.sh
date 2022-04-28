#!/usr/bin/env bash

# Set the constants
data_destination=/home/dan/data/garbage/docker-presto/data
data_source=/home/dan/Downloads/  # /home/dan/data/garbage/iris-hep-benchmark-presto/data
data_file=Run2012B_SingleMu-1000.parquet
presto_client=/home/dan/data/software/presto-client/presto.jar

# Upload the data
cp -f ${data_source}/${data_file} ${data_destination}
docker exec -it docker-presto_namenode_1 hadoop fs -mkdir /dataset
docker exec -it docker-presto_namenode_1 hadoop fs -put /data/native/${data_file} /dataset/
docker exec -it docker-presto_namenode_1 hadoop fs -ls /dataset

# Set up the table and the view
${presto_client} --server localhost:8080 --catalog hive --schema default --file /home/dan/data/garbage/iris-hep-benchmark-presto/scripts/make_db.sql
# ${presto_client} --server localhost:8080 --catalog hive --schema default --file /home/dan/data/garbage/iris-hep-benchmark-presto/scripts/create_view.sql
${presto_client} --server localhost:8080 --catalog hive --schema default --file /home/dan/data/garbage/iris-hep-benchmark-presto/queries/common/functions.sql