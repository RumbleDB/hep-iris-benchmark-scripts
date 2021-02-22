#!/usr/bin/env bash

if [[ $# != 2 ]]; then
	echo "Usage: execute_query.sh <query_id> <data_size>"
fi

java_ver=jdk1.8.0_271
spark_ver=spark-3.0.1-bin-hadoop2.7
rumble_ver=spark-rumble-1.10.0-for-spark-3.0.jar

# Find Java
export JAVA_HOME=`pwd`/$java_ver
export PATH=$JAVA_HOME/bin:$PATH

# Find Spark
export SPARK_HOME=`pwd`/$spark_ver

# Find Rumble
export RUMBLE=`pwd`/$rumble_ver

# Set-up the query
query_path="hep-iris-benchmark-jsoniq/queries/object-based/query-${1}/query.jq"
original="..\/..\/..\/data\/Run2012B_SingleMu.root"
new="~\/hep-iris-benchmark-jsoniq\/data\/Run2012B_SingleMu-${2}.parquet"
IFS=
query=$(sed "s/${original}/${new}/" ${query_path})

# Execute the query
cd "hep-iris-benchmark-jsoniq/queries/object-based/query-${1}"
echo `pwd`
echo ${query} > temp.jq
# cat temp.jq | echo 
time ${SPARK_HOME}/bin/spark-submit $RUMBLE --query-path temp.jq
# rm temp.jq