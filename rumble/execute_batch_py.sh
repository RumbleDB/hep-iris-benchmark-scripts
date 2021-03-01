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
# data_size=(150 1000 1500 2000 2500 3000 4000 8000 16000 32000 64000 128000 256000 512000 1024000 2048000 4096000 8192000 16384000 32768000 65536000)
data_size=(128000 256000 512000 1024000 2048000 4096000 8192000 16384000 32768000 65536000)
if [[ $# -ge 1 ]]; then
	data_size=($@)
fi

# Set the constants for this experiment
times_file_name="times.csv"
std_file_name="std.csv"
IFS=

# Set up the results files
LINE="query"
for size in "${data_size[@]}"
do
	LINE="${LINE},${size}"
done
echo "${LINE}" > ${times_file_name}

for size in "${query_idx[@]}"
do
	echo "${size}" >> ${times_file_name}
done

cp ${times_file_name} ${std_file_name}

# Start running the experiments
export _JAVA_OPTIONS="-Xmx14g"
spark-3.0.2-bin-hadoop2.7/bin/spark-submit --driver-memory 14 spark-rumble-1.10.0-for-spark-3.jar --server yes &
rumble_pid=$!
sleep 20

for size in "${data_size[@]}"
do
	python3 hep-iris-benchmark-jsoniq/test_queries.py  \
		--rumble-server=http://localhost:8001/jsoniq \
		--input-path=/data/${data_type}/Run2012B_SingleMu-${size}.parquet \
		-N ${size} \
		-k "${object_type}" \
		-vs --log-cli-level INFO \
		--run-count 5 \
		--warmup-count 2 \
		--out-file-times "`pwd`/${times_file_name}" \
		--out-file-std "`pwd`/${std_file_name}"
done

kill -9 ${rumble_pid}
