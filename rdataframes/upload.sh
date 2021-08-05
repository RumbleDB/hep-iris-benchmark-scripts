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
    dnsname=${dnsnames[0]}
    ssh -q ec2-user@$dnsname mkdir -p /data/input/
    for l in {0..16}
    do
        n=$((2**$l*1000))

        ssh -q ec2-user@$dnsname \
            aws s3 cp "$S3_INPUT_PATH/Run2012B_SingleMu_${n}.root" /data/input/
    done
) &>> "$deploy_dir/upload_$(date +%F-%H-%M-%S).log"
echo "Done uploading data..."
