#!/usr/bin/env bash

SCRIPT_PATH="$( cd "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"

NUM_INSTANCES="${1:-1}"
INSTANCE_TYPE="${2:-m5d.xlarge}"

# Load common functions
. "$SCRIPT_PATH/../common/ec2-helpers.sh"

# Deploy cluster
experiments_dir="$SCRIPT_PATH/../experiments"
mkdir -p "$experiments_dir"
deploy_cluster "$experiments_dir" $NUM_INSTANCES $INSTANCE_TYPE

# Deploy software on machines
echo "Deploying software..."
for dnsname in ${dnsnames[*]}
do
    (
        (
            scp -q "$SCRIPT_PATH/remote/run_benchmark.sh" ec2-user@$dnsname:/data
            scp -qr "$SCRIPT_PATH/queries" ec2-user@$dnsname:/data/opendata-benchmarks
            ssh -q ec2-user@$dnsname mkdir /data/input
            ssh -q ec2-user@$dnsname \
                docker build /data/opendata-benchmarks -t opendata-benchmarks
        ) &>> "$deploy_dir/deploy_$dnsname.log"
        echo "Done deploying $dnsname."
    ) &
done
wait
echo "Done deploying machines."
