#!/usr/bin/env bash

query_idx=(1 2 3 4 5 6-1 6-2 7 8-1 8-2)
data_size=(1000 2000 4000 8000 16000 32000 64000 128000 256000 512000 1024000 2048000 4096000 8192000 16384000 32768000 65536000)

# Set the constants for this experiment
times_file_name="/data/times.csv"
IFS=

# Set up the results files
LINE="query"
echo "query,num_events,running_time" > ${times_file_name}

# Start running the experiments
for size in "${data_size[@]}"
do
	python3 /data/iris-hep-benchmark-presto/test_queries.py  \
		-N ${size} \
		-vs --log-cli-level INFO \
		--run-count 2 \
		--warmup-count 1 \
		--out-file "${times_file_name}"
done
