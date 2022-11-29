#!/usr/bin/bash

SOURCE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"

NUM_RUNS=5
TMPDIR=/var/muellein/tmp/
DATADIR=/mnt/scratch/muellein/rumble-experiments-vldb21/

# Load common functions
. "$SOURCE_DIR/ec2-helpers.sh"

# Find cluster metadata
system_dir="$SOURCE_DIR/../$SYSTEM"
experiments_dir="$system_dir/experiments"
deploy_dir="$(discover_cluster "$experiments_dir")"
dnsnames=($(discover_dnsnames "$deploy_dir"))

# Create result dir
result_dir="$experiments_dir/results_$(date +%F-%H-%M-%S)"
mkdir -p $result_dir

function run_one {(
    trap 'exit 1' ERR

    platform=$1
    input_size=$2
    query=$3
    run_num=$4

    run_result_dir="$result_dir/run_$(date +%F-%H-%M-%S.%3N)"
    mkdir $run_result_dir

    tee "$run_result_dir/config.json" <<-EOF
		{
		    "system": "$SYSTEM",
		    "platform": "$platform",
		    "deploy_dir": "$(basename "$deploy_dir")",
		    "run_dir": "$(basename "$run_result_dir")",
		    "input_size": "$input_size",
		    "query": "$query",
		    "run_num": $run_num
		}
		EOF

    (
        cat "$system_dir/$platform/queries/$query."* | "$system_dir/$platform/run.sh" "$query" "$input_size"
        echo "Exit code: $?"
    ) 2>&1 | tee "$run_result_dir"/run.log
)}

function upload_singlecore {(
    trap 'exit 1' ERR

    data_set=$1
    input_size=$2

    # Delete old version
    ssh -q ec2-user@${dnsnames[0]} rm -rf /data/$data_set

    # Upload
    cd "$DATADIR/$data_set-$input_size"
    find . -type f | "$system_dir/singlecore/upload.sh"
)}

function upload_cluster {(
    trap 'exit 1' ERR

    data_set=$1
    input_size=$2

    "$system_dir/cluster/upload.sh" "$data_set" "$input_size"
)}

function run_many() {(
    trap 'exit 1' ERR

    platform=$1
    local -n input_size_configs=$2
    local -n queries_configs=$3

    for input_size in "${input_size_configs[@]}"
    do
        for data_set in "sensors" "github"
        do
            upload_$platform $data_set $input_size 2>&1 | tee "$result_dir/upload_$(date +%F-%H-%M-%S)"
        done

        for query in "${queries_configs[@]}"
        do
            for run_num in $(seq $NUM_RUNS)
            do
                run_one "$platform" "$input_size" "$query" "$run_num"
            done
        done
    done
)}
