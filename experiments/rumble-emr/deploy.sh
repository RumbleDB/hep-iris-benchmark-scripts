#!/usr/bin/env bash

SCRIPT_PATH="$( cd "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"

# Get the parameters
NUM_INSTANCES=${1:-1}
INSTANCE_TYPE=${2:-"m5d.xlarge"}
PORT_OFFSET=${3:-0}  # Useful when running multiple clusters in parallel

# Load common functions
. "$SCRIPT_PATH/../common/emr-helpers.sh"

EMR_VERSION="emr-6.2.0"
RUMBLE_VERSION="1.11.0"

# Deploy cluster
experiments_dir="$SCRIPT_PATH/../experiments/rumbledb"
mkdir -p "$experiments_dir"
deploy_cluster "$experiments_dir" $NUM_INSTANCES $INSTANCE_TYPE $EMR_VERSION
deploy_dir="$(discover_cluster "$experiments_dir")"
dnsname="$(discover_dnsname "$deploy_dir")"

# Deploy and start Rumble
echo "Deploying software..."
(
    ssh -q ec2-user@$dnsname -o StrictHostKeyChecking=accept-new true
    ssh -q ec2-user@$dnsname \
        <<-EOF
		wget https://github.com/RumbleDB/rumble/releases/download/v${RUMBLE_VERSION}/spark-rumble-${RUMBLE_VERSION}.jar \
		   -O - | sudo tee /var/lib/spark-rumble-for-spark-3.jar > /dev/null
		EOF
    ssh -q hadoop@$dnsname \
        <<-EOF
		nohup spark-submit /var/lib/spark-rumble-for-spark-3.jar --server yes --port 8001 &>> /tmp/rumble.log &
		EOF
) &> "$deploy_dir/deploy_$dnsname.log"
echo "Done."

# Set up SSH tunnel to head node
for p in 4040 8001 18080
do  
	ssh -L $(( ${p} + ${PORT_OFFSET} )):localhost:${p} -N -q hadoop@$dnsname &
	tunnelpid=$!
	echo "$tunnelpid" >> "$deploy_dir/tunnel.pid"
done