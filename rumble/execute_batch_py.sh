#!/usr/bin/env bash


if [[ $# -lt 1 ]]; then
	echo "Usage: ./execute_batch.sh (native|original) [data_size]*"
	exit
fi

data_type=$1
object_type="native-objects"
if [[ "${data_type}" == "original" ]]; then
	object_type="shredded-objects" 
fi
shift

query_idx=(1 2 3 4 5 6-1 6-2 7 8-1 8-2)
data_size=(1000 2000 4000 8000 16000 32000 64000 128000 256000 512000 1024000 2048000 4096000 8192000 16384000 32768000 65536000)
if [[ $# -ge 1 ]]; then
	data_size=($@)
fi

# Set the constants for this experiment
times_file_name="/data/times.csv"
IFS=

# Set up the results files
LINE="query"
echo "query,num_events,running_time" > ${times_file_name}

# Start running the experiments
export _JAVA_OPTIONS="-Xmx14g"
docker run --rm -d --cpuset-cpus 0 --memory="14g" --expose 8001 -p 8001:8001 -e _JAVA_OPTIONS="-Xmx14g" -e SPARK_SUBMIT_OPTIONS="--driver-memory 14 --conf spark.sql.shuffle.partitions=10" -v /data:/data/:ro rumbledb/rumble:v1.11.0-spark3 --server yes --host 0.0.0.0
rumble_pid=$!
sleep 20

for size in "${data_size[@]}"
do
	python3 /data/hep-iris-benchmark-jsoniq/test_queries.py  \
		--rumble-server=http://localhost:8001/jsoniq \
		--input-path=/data/${data_type}/Run2012B_SingleMu-${size}.parquet \
		-N ${size} \
		-k "${object_type}" \
		-vs --log-cli-level INFO \
		--run-count 2 \
		--warmup-count 1 \
		--out-file "${times_file_name}"
done

docker kill $(docker ps -q) 
