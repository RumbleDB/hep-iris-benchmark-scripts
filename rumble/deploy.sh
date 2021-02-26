#!/usr/bin/env bash

SCRIPT_PATH="$( cd "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"

SSH_KEY_NAME="Dan-LenovoT490"
NUM_INSTANCES=1
INSTANCE_TYPE="m5.large"
DOCKERIMAGE="rumbledb/rumble:v1.8.1-spark3"

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
            ssh -q ec2-user@$dnsname "bash -s" < rumble_environment.sh       
            scp ${SCRIPT_PATH}/execute_query.sh ${SCRIPT_PATH}/execute_batch.sh ec2-user@$dnsname:~
        ) &>> "$deploy_dir/deploy_$dnsname.log"
        echo "Done deploying $dnsname."
    ) &
done
wait
echo "Done deploying machines."
