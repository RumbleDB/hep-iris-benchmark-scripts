#!/usr/bin/bash

SOURCE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"

NUM_RUNS=1
NUM_ITERATIONS=3
MULTITHREADING=true

# Find instance IDs
instanceids=($(
    . "$SOURCE_DIR/../common/ec2-helpers.sh"
    deploy_dir="$(discover_cluster "$SOURCE_DIR/../experiments")"
    discover_instanceids "$deploy_dir"
))

# Find experiment directory
experiments_dir="$SOURCE_DIR/experiments"
query_cmd="$SOURCE_DIR/run_query.sh"

# Create result dir
experiment_dir="$experiments_dir/experiment_$(date +%F-%H-%M-%S)"
mkdir -p $experiment_dir

# Find S3 config
S3_INPUT_PATH=$(
    . "$SOURCE_DIR/../common/ec2-helpers.sh"
    echo "$S3_INPUT_PATH" | sed "s~^s3://~s3https://s3.$S3_REGION.amazonaws.com/~"
)
S3_ACCESS_KEY=$(
    . "$SOURCE_DIR/../common/ec2-helpers.sh"
    echo "$S3_ACCESS_KEY"
)
S3_SECRET_KEY=$(
    . "$SOURCE_DIR/../common/ec2-helpers.sh"
    echo "$S3_SECRET_KEY"
)

# Store instance information
aws ec2 describe-instances --instance-id $instanceids \
    > "$experiment_dir/instances.json"

function run_one {(
    trap 'exit 1' ERR

    num_events=$1
    query_id=$2
    run_num=$3

    run_dir="$experiment_dir/run_$(date +%F-%H-%M-%S.%3N)"
    mkdir $run_dir

    # Input path: choose one
    input_file="/data/Run2012B_SingleMu_${num_events}.root"
    #input_file="$S3_INPUT_PATH/Run2012B_SingleMu_${num_events}.root"

    tee "$run_dir/config.json" <<-EOF
		{
		    "system": "rdataframes",
		    "run_dir": "$(basename "$experiment_dir")/$(basename "$run_dir")",
		    "num_events": $num_events,
		    "query_id": "$query_id",
		    "run_num": $run_num,
		    "input_file": "$input_file",
		    "num_iterations": $NUM_ITERATIONS,
		    "multithreading": $MULTITHREADING
		}
		EOF

    (
        "$query_cmd" \
            -n $NUM_ITERATIONS \ \
            $query_id \
            "$input_file" \
            $MULTITHREADING
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

NUM_EVENTS=($(for l in {0..16}; do echo $((2**$l*1000)); done))
QUERY_IDS=(1 2 3 4 5 6a 6b 6 7 8)

run_many NUM_EVENTS QUERY_IDS
