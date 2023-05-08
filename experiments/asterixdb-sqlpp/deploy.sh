#!/usr/bin/bash

SCRIPT_PATH="$( cd "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"

NUM_INSTANCES="${1:-2}"
INSTANCE_TYPE="${2:-m5d.xlarge}"
NUM_PARTITIONS_PER_NODE="$3"

# Compute NUM_PARTITIONS_PER_NODE as one per real core
if [[ -z "$NUM_PARTITIONS_PER_NODE" ]]
then
    if [[ "$INSTANCE_TYPE" != *xlarge ]]; then NUM_PARTITIONS_PER_NODE=1
    elif [[ "$INSTANCE_TYPE" == *.xlarge ]]; then NUM_PARTITIONS_PER_NODE=2
    else NUM_PARTITIONS_PER_NODE=$((2*$(echo ${INSTANCE_TYPE#*.} | tr -d [a-z.])))
    fi
fi

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

            id=$(ssh -q ec2-user@$dnsname docker create ingomuellernet/asterixdb:asterixdb-rev-81c32493)
            ssh -q ec2-user@$dnsname \
                <<-EOF
				sudo yum install -y java
				docker cp $id:/opt/asterixdb .
				docker rm -v $id
				[[ -f ~/.ssh/id_rsa ]] || ssh-keygen -t rsa -N '' -f ~/.ssh/id_rsa
				echo "StrictHostKeyChecking No" > ~/.ssh/config
				chmod go-rwx ~/.ssh/config
				EOF

            ssh -q ec2-user@$dnsname \
                <<-EOF
				mkdir hadoop
				cd hadoop
				wget --progress=dot:giga https://archive.apache.org/dist/hadoop/core/hadoop-3.2.2/hadoop-3.2.2.tar.gz -O - | \
				    tar -xz --strip-components=1
				echo -n JAVA_HOME= | sudo tee -a /etc/environment
				readlink -f /usr/bin/java | xargs dirname | xargs dirname | sudo tee -a /etc/environment
				echo "${privateips[0]} namenode" | sudo tee -a /etc/hosts
				EOF
            scp -rq "$SCRIPT_PATH"/remote/hadoop ec2-user@${dnsname}:~/

            if [[ "$dnsname" == "${dnsnames[0]}" ]]
            then
                ssh -q ec2-user@$dnsname ./hadoop/bin/hdfs namenode -format
            fi
        ) &> "$deploy_dir/deploy_$dnsname.log"
        echo "Done deploying $dnsname."
    ) &
    sleep .1
done
wait
echo "Done deploying machines."

echo "Authorizing pair-wise keys..."
rm -f "$deploy_dir/authorized_keys"
for dnsname in ${dnsnames[*]}
do
    ssh -q ec2-user@$dnsname cat "~/.ssh/id_rsa.pub" >> "$deploy_dir/authorized_keys"
    sleep .1
done
for dnsname in ${dnsnames[*]}
do
    cat "$deploy_dir/authorized_keys" | ssh -q ec2-user@$dnsname 'cat - >> ~/.ssh/authorized_keys'
    sleep .1
done
echo "Done."

# Create cluster configuration and copy to master node
iodevices=$(for i in $(seq 1 $NUM_PARTITIONS_PER_NODE); do echo -n /data/asterixdb/iodevice$i,; done)
iodevices=${iodevices:0:-1}
echo "Deploying cluster configuration..."
(
    for (( i=1; i<${#instanceids[@]}; i++ ))
    do
        cat - <<-EOF
			[nc/${privatednsnames[$i]}]
			address=${privatednsnames[$i]}
			EOF
    done
    cat - <<-EOF
			[nc]
			app.class=org.apache.asterix.hyracks.bootstrap.NCApplicationEntryPoint
			command=asterixnc
			iodevices=$iodevices
			[cc]
			address=${privatednsnames[0]}
			EOF
) > "$deploy_dir"/cc.conf

scp -q "$deploy_dir"/cc.conf ec2-user@${dnsnames[0]}:~/asterixdb
echo "Done."

# Start name node
ssh -q ec2-user@${dnsnames[0]} <<-EOF
	nohup ~/hadoop/bin/hdfs namenode &>> /tmp/hdfs-namenode.log &
	EOF

# Start node controllers
echo "Starting node controllers..."
for dnsname in ${dnsnames[*]:1}
do
    (
       ssh -q ec2-user@$dnsname <<-EOF
			mkdir -p /tmp/asterixdb/logs/
			nohup ~/asterixdb/bin/asterixncservice &>> /tmp/asterixdb/logs/nc.log &
			EOF
    ) &
    sleep .1
done
wait
echo "Done starting node controllers."

# Start data nodes
echo "Starting data nodes..."
for dnsname in ${dnsnames[*]:1}
do
    (
       ssh -q ec2-user@$dnsname <<-EOF
			nohup ~/hadoop/bin/hdfs datanode &>> /tmp/hdfs-datanode.log &
			EOF
    ) &
    sleep .1
done
wait
echo "Done starting data nodes."

# Start cluster controller
ssh -q ec2-user@${dnsnames[0]} <<-EOF
	mkdir -p /tmp/asterixdb/logs/
	nohup ~/asterixdb/bin/asterixcc -config-file ~/asterixdb/cc.conf &>> /tmp/asterixdb/logs/cc.log &
	EOF
while [[ "$(echo "42" | "$SCRIPT_PATH/run.sh" | jq -r ".status")" != "success" ]]
do
    echo "Waiting for cluster controller to be up..."
done

# Set up SSH tunnel to head node
ssh -L 19002:localhost:19002 -L 19006:localhost:19006 -N -q ec2-user@${dnsnames[0]} &
tunnelpid=$!
echo "$tunnelpid" > "$deploy_dir/tunnel.pid"

echo "Master: ${dnsnames[0]}"
