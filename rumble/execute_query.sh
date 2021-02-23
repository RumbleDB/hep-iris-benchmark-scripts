#!/usr/bin/env bash

if [[ $# != 2 ]]; then
	echo "Usage: execute_query.sh <query_id> <data_size>"
	exit
fi

java_ver=jdk1.8.0_271
spark_ver=spark-3.0.2-bin-hadoop2.7
rumble_ver=spark-rumble-1.10.0-for-spark-3.jar

# Find Java
export JAVA_HOME=`pwd`/$java_ver
export PATH=$JAVA_HOME/bin:$PATH

# Find Spark
export SPARK_HOME=`pwd`/$spark_ver

# Find Rumble
export RUMBLE=`pwd`/$rumble_ver

# Set-up the query
cd "hep-iris-benchmark-jsoniq/queries/shredded-objects/query-${1}"
original="..\/..\/..\/data\/Run2012B_SingleMu.root"
new="\/home\/ec2-user\/hep-iris-benchmark-jsoniq\/data\/Run2012B_SingleMu-${2}.parquet"
IFS=
query=$(sed "s/${original}/${new}/" query.jq)

# Execute the query
echo `pwd`
echo ${query} > temp.jq
# cat temp.jq | echo 
time ${SPARK_HOME}/bin/spark-submit $RUMBLE --query-path temp.jq
# rm temp.jq