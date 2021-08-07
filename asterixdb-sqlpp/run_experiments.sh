#!/usr/bin/bash

SOURCE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"

INPUT_TABLE_FORMAT="Run2012B_SingleMu_%i_%s"
DATAVERSE="IrisHepBenchmark"
NUM_RUNS=3

# Find instance IDs
instanceids=($(
    . "$SOURCE_DIR/../common/ec2-helpers.sh"
    deploy_dir="$(discover_cluster "$SOURCE_DIR/../experiments")"
    discover_instanceids "$deploy_dir"
))

# Find DNS names
dnsnames=($(
    . "$SOURCE_DIR/../common/ec2-helpers.sh"
    deploy_dir="$(discover_cluster "$SOURCE_DIR/../experiments")"
    discover_dnsnames "$deploy_dir"
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

function print_stats {(
    for ((i = 0; i < ${#dnsnames[@]}; i++));
    do
        dnsname=${dnsnames[$i]}
        (
            ssh -q ec2-user@$dnsname \
                <<-'EOF'
				echo -n "CLK_TCK: "
				getconf CLK_TCK

				pids="$(/usr/sbin/pidof java)"
				for pid in $pids
                do
				    cat /proc/$pid/stat
                done

                cat /proc/net/dev
				EOF
        ) 2>&1 | while read line; do echo "$i|$line"; done
    done
)}

function run_one {(
    trap 'exit 1' ERR

    table_variant=$1
    num_events=$2
    query_id=$3
    run_num=$4

    input_table="$(printf $INPUT_TABLE_FORMAT $num_events $table_variant)"

    run_dir="$experiment_dir/run_$(date +%F-%H-%M-%S.%3N)"
    mkdir $run_dir

    tee "$run_dir/config.json" <<-EOF
		{
		    "system": "asterixdb",
		    "run_dir": "$(basename "$experiment_dir")/$(basename "$run_dir")",
		    "num_events": $num_events,
		    "input_table": "$input_table",
		    "query_id": "$query_id",
		    "run_num": $run_num
		}
		EOF

    (
        print_stats
        "$query_cmd" -vs --log-cli-level INFO \
            --asterixdb-server localhost:19002 \
            --asterixdb-dataverse $DATAVERSE \
            --input-table "$input_table" \
            --freeze-result true \
            --num-events $num_events \
            --query-id $query_id
        exit_code=$?
        echo "Exit code: $exit_code"
        echo $exit_code > "$run_dir"/exit_code.log
        print_stats
    ) 2>&1 | tee "$run_dir"/run.log
)}

function run_many() {(
    trap 'exit 1' ERR

    local -n table_variants_configs=$1
    local -n num_events_configs=$2
    local -n query_ids_configs=$3

    for table_variant in "${table_variants_configs[@]}"
    do
        for num_events in "${num_events_configs[@]}"
        do
            for query_id in "${query_ids_configs[@]}"
            do
                for run_num in $(seq $NUM_RUNS)
                do
                    run_one "$table_variant" "$num_events" "$query_id" "$run_num"
                done
            done
        done
    done
)}

TABLE_VARIANTS=(typed_internal untyped_internal typed_json_hdfs untyped_json_hdfs typed_json_s3 untyped_json_s3 untyped_parquet_hdfs untyped_parquet_s3 untyped_parquet_local)
NUM_EVENTS=($(for l in {0..10}; do echo $((2**$l*1000)); done))
QUERY_IDS=($(for q in 1 2 3 4 5 6-1 6-2 7 8; do echo query-$q; done))

run_many TABLE_VARIANTS NUM_EVENTS QUERY_IDS

TABLE_VARIANTS=(typed_internal untyped_internal typed_json_hdfs untyped_json_hdfs typed_json_s3 untyped_json_s3 untyped_parquet_hdfs untyped_parquet_s3 untyped_parquet_local)
NUM_EVENTS=($(for l in {11..16}; do echo $((2**$l*1000)); done))
QUERY_IDS=($(for q in 1 2 3 4 5 7 8; do echo query-$q; done))

run_many TABLE_VARIANTS NUM_EVENTS QUERY_IDS
