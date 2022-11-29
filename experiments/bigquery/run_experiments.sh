#!/usr/bin/bash

SOURCE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"

# Load config file
config_file="$SOURCE_DIR/../common/config.sh"
if ! [ -f "$config_file" ]
then
    echo "Config file config.sh not found." >&2
    exit 1
else
    . "$config_file"
fi

INPUT_TABLE_FORMAT="Run2012B_SingleMu_restructured_external_%i_view"
NUM_RUNS=3

experiments_dir="$SOURCE_DIR"/experiments
query_cmd="$SOURCE_DIR"/queries/test_queries.py

# Create result dir
experiment_dir="$experiments_dir/experiment_$(date +%F-%H-%M-%S)"
mkdir -p $experiment_dir

function run_one {(
    trap 'exit 1' ERR

    num_events=$1
    query_id=$2
    run_num=$3

    input_table="$(printf $INPUT_TABLE_FORMAT $num_events)"

    run_dir="$experiment_dir/run_$(date +%F-%H-%M-%S.%3N)"
    mkdir $run_dir

    tee "$run_dir/config.json" <<-EOF
		{
		    "system": "bigquery",
		    "run_dir": "$(basename "$run_dir")",
		    "num_events": $num_events,
		    "input_table": "$input_table",
		    "query_id": "$query_id",
		    "run_num": $run_num
		}
		EOF

    (
        "$query_cmd" -vs --log-cli-level INFO \
            --bigquery-dataset "$GS_DATASET_ID" \
            --input-table "$input_table" \
            --num-events $num_events \
            --query-id $query_id \
            --freeze-result
        exit_code=$?
        echo "Exit code: $exit_code"
        echo $exit_code > "$run_dir"/exit_code.log
    ) 2>&1 | tee "$run_dir"/run.log
)}

function run_many() {(
    trap 'exit 1' ERR

    local -n num_events_configs=$1
    local -n query_ids_configs=$2

    for num_events in "${num_events_configs[@]}"
    do
        for query_id in "${query_ids_configs[@]}"
        do
            for run_num in $(seq $NUM_RUNS)
            do
                run_one "$num_events" "$query_id" "$run_num"
            done
        done
    done
)}

NSF1=53446198

NUM_EVENTS=($(for l in {0..15}; do echo $((2**$l*1000)); done) $(for l in {0..7}; do echo $((2**$l*$NSF1)); done))
QUERY_IDS=($(for q in 1 2 3 4 5 6-1 6-2 7 8; do echo query-$q; done))

run_many NUM_EVENTS QUERY_IDS
