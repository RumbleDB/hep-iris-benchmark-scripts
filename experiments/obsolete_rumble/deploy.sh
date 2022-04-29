#!/usr/bin/env bash

SCRIPT_PATH="$( cd "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"

# Get the parameters
NUM_INSTANCES=${1:-1}
INSTANCE_TYPE=${2:-"m5d.xlarge"}
PORT_OFFSET=${3:-0}  # Useful when running multiple clusters in parallel

# Load common functions
. "$SCRIPT_PATH/../common/ec2-helpers.sh"

# Deploy cluster
experiments_dir="$SCRIPT_PATH/../experiments/rumble"
mkdir -p "$experiments_dir"
deploy_cluster "$experiments_dir" $NUM_INSTANCES $INSTANCE_TYPE

sed "s/14/${memory}/g" ${SCRIPT_PATH}/remote/environment.sh > environment.sh

# Deploy software on machines
echo "Deploying software..."
for dnsname in ${dnsnames[*]}
do
	(
		(
			scp -r "$SCRIPT_PATH/queries" ec2-user@$dnsname:/data
			ssh -q ec2-user@$dnsname "bash -s" < environment.sh       
		) &>> "$deploy_dir/deploy_$dnsname.log"
		echo "Done deploying $dnsname."
	) &
done
wait
echo "Done deploying machines."

# Set up SSH tunnel to head node
for p in 4040 8001 18080
do  
	ssh -L $(( ${p} + ${PORT_OFFSET} )):localhost:${p} -N -q ec2-user@${dnsname[0]} &
	tunnelpid=$!
	echo "$tunnelpid" >> "$deploy_dir/tunnel.pid"
done