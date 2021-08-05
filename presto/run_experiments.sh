#!/usr/bin/bash

SOURCE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"

PRESTO_CMD="$SOURCE_DIR"/queries/scripts/presto.sh
INPUT_TABLE_FORMAT="Run2012B_SingleMu_%i"
NUM_RUNS=3

# Find instance IDs
instanceids=($(
    . "$SOURCE_DIR/../common/ec2-helpers.sh"
    deploy_dir="$(discover_cluster "$SOURCE_DIR/../experiments")"
    discover_instanceids "$deploy_dir"
))

# Find experiment directory
experiments_dir="$SOURCE_DIR"/experiments
query_cmd="$SOURCE_DIR"/queries/test_queries.py

# Create result dir
experiment_dir="$experiments_dir/experiment_$(date +%F-%H-%M-%S)"
mkdir -p $experiment_dir

# Store instance information
aws ec2 describe-instances --instance-id $instanceids \
    > "$experiment_dir/instances.json"

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
		    "system": "presto",
		    "run_dir": "$(basename "$experiment_dir")/$(basename "$run_dir")",
		    "num_events": $num_events,
		    "input_table": "$input_table",
		    "query_id": "$query_id",
		    "run_num": $run_num
		}
		EOF

    (
        "$query_cmd" -vs --log-cli-level INFO \
            --presto-cmd "$PRESTO_CMD" \
            --presto-server "localhost:8080" \
            --input-table "$input_table" \
            --freeze-result true \
            --num-events $num_events \
            --query-id $query_id
        exit_code=$?
        echo "Exit code: $exit_code"
        echo $exit_code > "$run_dir"/exit_code.log
    ) 2>&1 | tee "$run_dir"/run.log

    execution_id="$(cat "$run_dir/run.log" | grep -oE "Query ID: .*" | cut -f3 -d' ')"
    (
        if [[ -n "$query_id" ]]; then
            wget http://localhost:8080/v1/query/$execution_id -qO - | python3 -m json.tool
        else
            echo "{}"
        fi
    ) > "$run_dir"/query.json
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

NUM_EVENTS=($(for l in {0..15}; do echo $((2**$l*1000)); done) $(for l in {0..0}; do echo $((2**$l*$NSF1)); done))
QUERY_IDS=($(for q in 1 2 3 4 5 6-1 6-2 7 8; do echo query-$q; done))

run_many NUM_EVENTS QUERY_IDS

NUM_EVENTS=($(for l in {0..15}; do echo $((2**$l*1000)); done) $(for l in {1..6}; do echo $((2**$l*$NSF1)); done))
QUERY_IDS=($(for q in 1 2 3 4 5 7 8; do echo query-$q; done))

run_many NUM_EVENTS QUERY_IDS

NUM_EVENTS=($(for l in {7..7}; do echo $((2**$l*$NSF1)); done))
QUERY_IDS=($(for q in 1 2 3 4 5; do echo query-$q; done))

run_many NUM_EVENTS QUERY_IDS
