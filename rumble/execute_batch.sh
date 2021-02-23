#!/usr/bin/env bash


if [[ $# != 1 ]]; then
	echo "Usage: execute_query.sh <data_size>"
	exit
fi

# Set the constants for this experiment
# data_size=(150 1000 1500 2000 2500 3000)
file_name="results.csv"
query_idx=(1 2 3 4 5 6-1 6-2 7 8-1 8-2)
data_size=(${1})
IFS=

# Set up the results file
# echo "query,150,1000,1500,2000,2500,3000" > ${file_name}
echo "query,${1}" > ${file_name}

# Start running the experiments
for idx in "${query_idx[@]}"
do
	LINE="${idx}"
	for size in "${data_size[@]}"
	do
		res=$(./execute_query.sh ${idx} ${size} 2>&1 > /dev/null | grep real | grep -oP "\d+m\d+\.?\d*s")
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