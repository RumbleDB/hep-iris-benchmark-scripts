SOURCE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"

if ! [ -f "$SOURCE_DIR/config.sh" ]
then
    echo "Config file config.sh not found. You probably forgot to add a config.sh file to your common folder. See README for more details." >&2
    exit 1
else
    . "$SOURCE_DIR/config.sh"
fi

function discover_cluster {
    trap 'echo "Error!"; exit 1' ERR
    experiments_dir=$1
    ls -d "$experiments_dir"/deploy_* | sort | tail -n1
}

function discover_clusterid {
    trap 'echo "Error!"; exit 1' ERR
    deploy_dir=$1
    cat "$deploy_dir/create-cluster.json" | jq -r ".ClusterId"
}

function discover_dnsname {
    trap 'echo "Error!"; exit 1' ERR
    deploy_dir=$1
    cat "$deploy_dir/describe-cluster.json" | jq -r ".Cluster.MasterPublicDnsName"
}

function terminate_cluster {
    trap 'echo "Error!"; exit 1' ERR
    deploy_dir=$1

    clusterid="$(discover_clusterid "$deploy_dir")"
    echo "Terminating cluster with ID $clusterid..."
    aws emr terminate-clusters --cluster-ids $clusterid

    echo -n "New state: "
    aws emr describe-cluster --cluster-id $clusterid | jq -r .Cluster.Status.State
}

function deploy_cluster {
    trap 'echo "Error!"; exit 1' ERR

    experiments_dir=$1
    num_instances=$2
    instance_type=$3
    emr_version=$4

    # Set up deploy directory
    [ -d "$experiments_dir" ]
    deploy_dir="${experiments_dir}/deploy_$(date +%F-%H-%M-%S)"
    mkdir -p "$deploy_dir"

    # Create cluster
    aws emr create-cluster \
            --name "Spark cluster" --use-default-roles --applications Name=Spark \
            --release-label $emr_version \
            --ec2-attributes KeyName="$SSH_KEY_NAME" \
            --instance-type $instance_type --instance-count $num_instances \
        > "$deploy_dir/create-cluster.json"
    clusterid="$(discover_clusterid "$deploy_dir")"
    echo "Starting cluster with ID $clusterid..."

    # Wait for cluster to come up
    state=""
    SECONDS=0
    while [[ "$state" != "WAITING" ]]
    do
        state="$(aws emr describe-cluster --cluster-id $clusterid | jq -r .Cluster.Status.State)"
        echo "${SECONDS}s: Waiting for cluster to come up (current state: $state)..."
        sleep 10s
    done
    echo "Ready after ${SECONDS}s."

    # Log cluster metadata
    aws emr describe-cluster --cluster-id $clusterid \
        > "$deploy_dir/describe-cluster.json"
    dnsname="$(discover_dnsname "$deploy_dir")"
    echo "Master node: $dnsname"
}
