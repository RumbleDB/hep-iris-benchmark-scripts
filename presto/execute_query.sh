#!/usr/bin/env bash

if [[ $# != 1 ]]; then
	echo "./execute_query.sh <query_id>"
	exit
fi

# Set the constants
presto_client=/home/dan/data/software/presto-client/presto.jar
query_file="/home/dan/data/garbage/iris-hep-benchmark-presto/queries/${1}/query.sql"

# Run the query
${presto_client} --server localhost:8080 --catalog hive --schema default --file ${query_file}