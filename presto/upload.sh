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
    for l in {0..16}
    do
        n=$((2**$l*1000))

        s3a_input_path="$(echo "$S3_INPUT_PATH" | sed 's~^s3://~s3a://~')"

        "$SCRIPT_PATH/queries/scripts/create_table.py" \
            --presto-server localhost:8080 \
            --variant native \
            --table-name Run2012B_SingleMu_${n} \
            --location "$s3a_input_path/Run2012B_SingleMu_restructured_${n}/" \
            --view-name Run2012B_SingleMu_restructured_${n}_view
    done
) &>> "$deploy_dir/upload_$(date +%F-%H-%M-%S).log"
echo "Done uploading data..."
