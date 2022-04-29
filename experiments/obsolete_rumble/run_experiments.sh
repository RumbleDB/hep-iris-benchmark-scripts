#!/usr/bin/env bash

SOURCE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"

PORT_OFFSET=${1:-0}  # Useful when running multiple clusters in parallel

INPUT_TABLE_FORMAT="/data/native/Run2012B_SingleMu-%i.parquet"
NUM_RUNS=3

experiments_dir="$SOURCE_DIR"/experiments/rumble
query_cmd="$SOURCE_DIR"/queries/test_queries.py

. "$SOURCE_DIR/conf.sh"

stat_port=$(( 4040 + ${PORT_OFFSET} ))
query_port=$(( 8001 + ${PORT_OFFSET} ))

# Create result dir
experiment_dir="$experiments_dir/experiment_$(date +%F-%H-%M-%S)"
mkdir -p $experiment_dir

function run_one {(
	trap 'exit 1' ERR

	num_events=$1
	query_id=$2
	run_num=$3
	warmup=$4

	input_table="$(printf $INPUT_TABLE_FORMAT $num_events)"

	run_dir="$experiment_dir/run_$(date +%F-%H-%M-%S.%3N)"
	mkdir $run_dir

	tee "$run_dir/config.json" <<-EOF
		{
			"VM": "${instance}",
			"system": "rumble",
			"run_dir": "$(basename "$experiment_dir")/$(basename "$run_dir")",
			"num_events": $num_events,
			"input_table": "$input_table",
			"query_id": "$query_id",
			"run_num": $run_num
		}
		EOF

	application_id=$(curl "http://localhost:${stat_port}/api/v1/applications/" | jq -r '[.[]|select(.name=="jsoniq-on-spark")][0]["id"]')
	entries=$(curl "http://localhost:${stat_port}/api/v1/applications/${application_id}/jobs" | jq length)
	entries_sql=$(curl "http://localhost:${stat_port}/api/v1/applications/${application_id}/sql?length=100000000" | jq length)
	(
		"$query_cmd" -vs --log-cli-level INFO \
			--freeze-result \
			--input-path="$input_table" \
			--rumble-server="http://localhost:${query_port}/jsoniq" \
			--num-events=$num_events \
			--query-id="$query_id"
		exit_code=$?
		echo "Exit code: $exit_code"
		echo $exit_code > "$run_dir"/exit_code.log
	) 2>&1 | tee "$run_dir"/run.log
	entries=$(( $(curl "http://localhost:${stat_port}/api/v1/applications/${application_id}/jobs" | jq length) - $entries ))
	entries_sql=$(( $(curl "http://localhost:${stat_port}/api/v1/applications/${application_id}/sql?length=100000000" | jq length) - $entries_sql ))

	if [ "$warmup" != "yes" ]; then
		python3 get_metrics.py ${application_id} ${entries} ${entries_sql} ${run_dir} --port=${stat_port}
	fi
)}

function run_many() {(
	trap 'exit 1' ERR

	local -n num_events_configs=$1
	local -n query_ids_configs=$2
	local warmup=$3

	for num_events in "${num_events_configs[@]}"
	do
		for query_id in "${query_ids_configs[@]}"
		do
			for run_num in $(seq $NUM_RUNS)
			do
				run_one "$num_events" "$query_id" "$run_num" "$warmup"
			done
		done
	done
)}

# Start up Spark to avoid curl errors
run_one 1000 native-objects/query-1 0 yes

# Run the warmups
NUM_EVENTS=($(for l in {0..0}; do echo $((2**$l*1000)); done))
QUERY_IDS=($(for q in 1 2 3 4 5 6-1 6-2 7 8; do echo native-objects/query-$q; done))
run_many NUM_EVENTS QUERY_IDS yes

# Run the benchmarks
Run the actual queries
NUM_EVENTS=($(for l in {0..11}; do echo $((2**$l*1000)); done))
QUERY_IDS=($(for q in 1 2 3 4 5 6-1 6-2 7 8; do echo native-objects/query-$q; done))

run_many NUM_EVENTS QUERY_IDS no

NUM_EVENTS=($(for l in {12..12}; do echo $((2**$l*1000)); done))
QUERY_IDS=($(for q in 1 2 3 4 5 7 8; do echo native-objects/query-$q; done))

run_many NUM_EVENTS QUERY_IDS no

NUM_EVENTS=($(for l in {13..16}; do echo $((2**$l*1000)); done))
QUERY_IDS=($(for q in 1 2 3; do echo native-objects/query-$q; done))

run_many NUM_EVENTS QUERY_IDS no