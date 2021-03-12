#!/usr/bin/env bash

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
	python3 /data/queries/test_queries.py  \
		-N ${size} \
		-vs --log-cli-level INFO \
		--presto-cmd /data/queries/scripts/run_presto.sh \
		--run-count 2 \
		--warmup-count 1 \
		--out-file "${times_file_name}"
done
