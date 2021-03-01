#!/usr/bin/env bash


if [[ $# -lt 1 ]]; then
	echo "Usage: ./execute_batch.sh (native|original) [data_size]*"
	exit
fi

data_type=$1
shift

query_idx=(1 2 3 4 5 6-1 6-2 7 8-1 8-2)
# data_size=(150 1000 1500 2000 2500 3000 4000 8000 16000 32000 64000 128000 256000 512000 1024000 2048000 4096000 8192000 16384000 32768000 65536000)
data_size=(128000 256000 512000 1024000 2048000 4096000 8192000 16384000 32768000 65536000)
if [[ $# -ge 1 ]]; then
	data_size=($@)
fi

# Set the constants for this experiment
file_name="results.csv"
IFS=

# Set up the results file
LINE="query"
for size in "${data_size[@]}"
do
	LINE="${LINE},${size}"
done
echo "${LINE}" > ${file_name}

# Start running the experiments
for idx in "${query_idx[@]}"
do
	LINE="${idx}"
	for size in "${data_size[@]}"
	do
		res=$(./execute_query.sh ${data_type} ${idx} ${size} 2>&1 > /dev/null | grep real | grep -oP "\d+m\d+\.?\d*s")
		min=$(echo $res | grep -oP "\d+m" | grep -oP "\d+")
		sec=$(echo $res | grep -oP "\d+\.?\d*s" | grep -oP "\d+\.?\d*")
		t=$( echo "$min * 60 + $sec" | bc) 
		echo "(Query ${idx}) res = " ${res}
		echo "(Query ${idx}) min = " ${min}
		echo "(Query ${idx}) sec = " ${sec}
		echo "(Query ${idx}) t = " ${t}
		LINE="${LINE},${t}"
	done
	echo "${LINE}" >> ${file_name}
done