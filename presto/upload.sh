#!/usr/bin/env bash

SCRIPT_PATH="$( cd "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"

# Load common functions
. "$SCRIPT_PATH/../common/ec2-helpers.sh"

# Find deploy directory
experiments_dir="$SCRIPT_PATH/../experiments"
deploy_dir="$(discover_cluster "$experiments_dir")"
dnsnames=($(discover_dnsnames "$deploy_dir"))

# Upload data
echo "Uploading data..."
(
    ssh -q ec2-user@${dnsnames[0]} "bash -s" < "$SCRIPT_PATH"/remote/upload.sh

    # Set up the table and the view
    cat "$SCRIPT_PATH"/queries/queries/common/functions.sql |
		"$SCRIPT_PATH"/queries/scripts/run_presto.sh \
            --file /dev/stdin

    for i in 1000 2000 4000 8000 16000 32000 64000 128000 256000 512000 1024000 2048000 4096000 8192000 16384000 32768000 65536000
    do
        sed "s/{i}/${i}/g" "$SCRIPT_PATH"/queries/scripts/make_db_native.sql | \
            "$SCRIPT_PATH"/queries/scripts/run_presto.sh \
                --file /dev/stdin
    done
) &>> "$deploy_dir/upload_$(date +%F-%H-%M-%S).log"
echo "Done uploading data..."
