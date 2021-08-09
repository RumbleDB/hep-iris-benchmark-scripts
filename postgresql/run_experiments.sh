#!/usr/bin/env bash

SOURCE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
EXP_DIR="${SOURCE_DIR}/../experiments"

INPUT_TABLE_FORMAT="Run2012B_SingleMu_%i"
NUM_RUNS=3

# Find instance IDs and names
. "$SOURCE_DIR/../common/ec2-helpers.sh"
deploy_dir="$(discover_cluster ${EXP_DIR})"
instanceids=($(discover_instanceids "$deploy_dir"))
dnsnames=($(discover_dnsnames "$deploy_dir"))

# Find experiment directory
QUERY_CMD="docker exec psql_deploy python3 /data/queries/test_queries.py"

# Create result dir
experiment_dir="$EXP_DIR/experiment_$(date +%F-%H-%M-%S)"
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
		    "system": "postgresql",
		    "run_dir": "$(basename "$experiment_dir")/$(basename "$run_dir")",
		    "num_events": $num_events,
		    "input_table": "$input_table",
		    "query_id": "$query_id",
		    "run_num": $run_num
		}
		EOF

    # Run the query
    (
        ssh ec2-user@${dnsnames[0]} \
            $QUERY_CMD -vs --log-cli-level INFO \
            --input-table "$input_table" \
            --freeze-result true \
            --num-events $num_events \
            --query-id $query_id
        exit_code=$?
        echo "Exit code: $exit_code"
        echo $exit_code > "$run_dir"/exit_code.log
    ) 2>&1 | tee "$run_dir"/run.log

    # Get the results of the query and store them locally
    ssh ec2-user@${dnsnames[0]} cat "/data/query.log" \
        | jq --arg num_events ${num_events} --arg query_id ${query_id} \
        --arg run_num ${run_num} \
        '. + {num_events: $num_events, query_id: $query_id, run_num: $run_num}' \
        >> $run_dir/query_stats.log
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


NUM_EVENTS=(1000)
QUERY_IDS=($(for q in 1 2 3 4 5 6-1 6-2 7 8; do echo query-$q; done))
run_many NUM_EVENTS QUERY_IDS
python3 postprocess_statistics.py ${EXP_DIR}
exit 

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
