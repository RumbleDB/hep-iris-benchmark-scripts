#!/usr/bin/env bash

SCRIPT_PATH="$( cd "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"

NUM_INSTANCES="${1:-1}"
INSTANCE_TYPE="${2:-m5d.xlarge}"
NUM_PARTITIONS_PER_NODE=$3


# Compute NUM_PARTITIONS_PER_NODE as one per real core
if [[ -z "$NUM_PARTITIONS_PER_NODE" ]]
then
    if [[ "$INSTANCE_TYPE" != *xlarge ]]; then NUM_PARTITIONS_PER_NODE=1
    elif [[ "$INSTANCE_TYPE" == *.xlarge ]]; then NUM_PARTITIONS_PER_NODE=2
    else NUM_PARTITIONS_PER_NODE=$((2*$(echo ${INSTANCE_TYPE#*.} | tr -d [a-z.])))
    fi
fi

# Double the number of partitions such that it's equal to the vCPUs
NUM_PARTITIONS_PER_NODE=$(( ${NUM_PARTITIONS_PER_NODE} * 2 ))
echo "Partition count: " ${NUM_PARTITIONS_PER_NODE}

# Load common functions
. "$SCRIPT_PATH/../common/ec2-helpers.sh"

# Deploy cluster
experiments_dir="$SCRIPT_PATH/../experiments/postgres"
mkdir -p "$experiments_dir"
deploy_cluster "$experiments_dir" $NUM_INSTANCES $INSTANCE_TYPE

# Deploy software on machines
echo "Deploying software..."
for dnsname in ${dnsnames[*]}
do
    (
        (
            scp -r "$SCRIPT_PATH/queries" ec2-user@$dnsname:/data
            scp "$SCRIPT_PATH/etc/postgresql.conf" ec2-user@$dnsname:/data
            ssh -q ec2-user@$dnsname "bash -s" < "$SCRIPT_PATH"/environment.sh ${NUM_PARTITIONS_PER_NODE}
        ) &>> "$deploy_dir/deploy_$dnsname.log"
        echo "Done deploying $dnsname."
    ) &
done
wait
echo "Done deploying machines."
