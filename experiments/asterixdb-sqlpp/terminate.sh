#!/usr/bin/bash

SCRIPT_PATH="$( cd "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"

# Load common functions
. "$SCRIPT_PATH/../common/ec2-helpers.sh"

# Find cluster metadata
experiments_dir="$SCRIPT_PATH/../experiments"
deploy_dir="$(discover_cluster "$experiments_dir")"
dnsnames=($(discover_dnsnames "$deploy_dir"))

# Download logs
for (( i=0; i<${#dnsnames[@]}; i++ ))
do
    (
        echo "Downloading logs from node $i..."
        scp -q -o ConnectTimeout=10 -r ${dnsnames[$i]}:/tmp/asterixdb/logs "$deploy_dir/logs_${dnsnames[$i]}"
    ) &
    sleep .1
done
wait
echo "Done"

# Close SSH tunnel
kill $(cat "$deploy_dir/tunnel.pid" || echo -1 ) || echo "Could not find SSH tunnel..."

# Terminate
terminate_cluster "$deploy_dir"
