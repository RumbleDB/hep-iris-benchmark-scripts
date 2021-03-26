#!/usr/bin/env bash

SCRIPT_PATH="$( cd "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"

# Load common functions
. "$SCRIPT_PATH/../common/ec2-helpers.sh"

# Find deploy directory
experiments_dir="$SCRIPT_PATH/../experiments"
deploy_dir="$(discover_cluster "$experiments_dir")"
dnsnames=($(discover_dnsnames "$deploy_dir"))

# Run query
dnsname=${dnsnames[0]}
ssh -q ec2-user@$dnsname \
    docker run --rm -v /data/input/:/data/:ro \
        masonproffitt/rdataframe-benchmarks:0.0 \
            /root/util/run_benchmark.sh "$@"
