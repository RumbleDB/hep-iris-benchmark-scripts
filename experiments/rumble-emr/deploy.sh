#!/usr/bin/env bash

SCRIPT_PATH="$( cd "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"

# Load common functions
. "$SCRIPT_PATH/../common/emr-helpers.sh"
. "$SCRIPT_PATH/conf.sh"

NUM_INSTANCES=${count}
INSTANCE_TYPE=${instance}
EMR_VERSION="emr-6.2.0"
RUMBLE_VERSION="1.11.0"

# Deploy cluster
experiments_dir="$SCRIPT_PATH/../experiments"
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
	ssh -L $(( ${p} + ${offset} )):localhost:${p} -N -q hadoop@$dnsname &
	tunnelpid=$!
	echo "$tunnelpid" >> "$deploy_dir/tunnel.pid"
done