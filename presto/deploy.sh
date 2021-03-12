#!/usr/bin/env bash

SCRIPT_PATH="$( cd "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"

NUM_INSTANCES=1
INSTANCE_TYPE="m5d.xlarge"

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
            scp -r "$SCRIPT_PATH/docker-presto" ec2-user@$dnsname:/data
            ssh -q ec2-user@$dnsname "bash -s" < "$SCRIPT_PATH"/remote/environment.sh
        ) &>> "$deploy_dir/deploy_$dnsname.log"
        echo "Done deploying $dnsname."
    ) &
done
wait
echo "Done deploying machines."

# Set up SSH tunnel to head node
ssh -L 8080:localhost:8080 -N -q ${dnsname[0]} &
tunnelpid=$!
echo "$tunnelpid" > "$deploy_dir/tunnel.pid"
