#!/usr/bin/env bash

SCRIPT_PATH="$( cd "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"

# Load common functions
. "$SCRIPT_PATH/../common/ec2-helpers.sh"

# Find deploy directory
experiments_dir="$SCRIPT_PATH/../experiments"
deploy_dir="$(discover_cluster "$experiments_dir")"
dnsnames=($(discover_dnsnames "$deploy_dir"))

# Upload data
echo "Uploading data..."
(
    for l in {0..16}
    do
        n=$((2**$l*1000))

        #
        # JSON
        #

        dataset_name="Run2012B_SingleMu_restructured_json_${n}"

        # Copy from S3 to HDFS
        ssh -q ec2-user@${dnsnames[0]} \
            <<-EOF
			mkdir -p /data/tmp
			aws s3 cp --no-progress --recursive "$S3_INPUT_PATH/$dataset_name/" "/data/tmp/$dataset_name/"
			./hadoop/bin/hadoop fs -mkdir "/$dataset_name"
			./hadoop/bin/hadoop fs -put "/data/tmp/$dataset_name/" /
			rm -r "/data/tmp/$dataset_name/"
			EOF

        # Internal relations loaded from files on HDFS
        "$SCRIPT_PATH/queries/scripts/create_table.py" \
            --asterixdb-server localhost:19002 \
            --hdfs-server hdfs://namenode:8020 \
            --external-path "/$dataset_name/*.json.gz" \
            --dataset-name Run2012B_SingleMu_${n}_untyped_internal \
            --datatype any --file-format json --storage-location internal \
            --log-level INFO --asterixdb-dataverse IrisHepBenchmark

        "$SCRIPT_PATH/queries/scripts/create_table.py" \
            --asterixdb-server localhost:19002 \
            --hdfs-server hdfs://namenode:8020 \
            --external-path "/$dataset_name/*.json.gz" \
            --dataset-name Run2012B_SingleMu_${n}_typed_internal \
            --datatype event --file-format json --storage-location internal \
            --log-level INFO --asterixdb-dataverse IrisHepBenchmark

        # External relations using files on HDFS
        "$SCRIPT_PATH/queries/scripts/create_table.py" \
            --asterixdb-server localhost:19002 \
            --hdfs-server hdfs://namenode:8020 \
            --external-path "/$dataset_name/*.json.gz" \
            --dataset-name Run2012B_SingleMu_${n}_untyped_json_hdfs \
            --datatype any --file-format json --storage-location external \
            --log-level INFO --asterixdb-dataverse IrisHepBenchmark

        "$SCRIPT_PATH/queries/scripts/create_table.py" \
            --asterixdb-server localhost:19002 \
            --hdfs-server hdfs://namenode:8020 \
            --external-path "/$dataset_name/*.json.gz" \
            --dataset-name Run2012B_SingleMu_${n}_typed_json_hdfs \
            --datatype event --file-format json --storage-location external \
            --log-level INFO --asterixdb-dataverse IrisHepBenchmark

        # External relations using files on S3
        "$SCRIPT_PATH/queries/scripts/create_table.py" \
            --asterixdb-server localhost:19002 \
            --bucket-name $S3_INPUT_BUCKET \
            --bucket-region $S3_REGION \
            --secret-access-key $S3_SECRET_KEY \
            --access-key-id $S3_ACCESS_KEY \
            --external-path "$dataset_name/" \
            --dataset-name Run2012B_SingleMu_${n}_untyped_json_s3 \
            --datatype any --file-format json --storage-location external \
            --log-level INFO --asterixdb-dataverse IrisHepBenchmark

        "$SCRIPT_PATH/queries/scripts/create_table.py" \
            --asterixdb-server localhost:19002 \
            --bucket-name $S3_INPUT_BUCKET \
            --bucket-region $S3_REGION \
            --secret-access-key $S3_SECRET_KEY \
            --access-key-id $S3_ACCESS_KEY \
            --external-path "$dataset_name/" \
            --dataset-name Run2012B_SingleMu_${n}_typed_json_s3 \
            --datatype event --file-format json --storage-location external \
            --log-level INFO --asterixdb-dataverse IrisHepBenchmark

        #
        # Parquet
        #

        dataset_name="Run2012B_SingleMu_restructured_${n}"

        # Copy from S3 to HDFS
        ssh -q ec2-user@${dnsnames[0]} \
            <<-EOF
			mkdir -p /data/tmp
			aws s3 cp --no-progress --recursive "$S3_INPUT_PATH/$dataset_name/" "/data/tmp/$dataset_name/"
			./hadoop/bin/hadoop fs -mkdir "/$dataset_name"
			./hadoop/bin/hadoop fs -put "/data/tmp/$dataset_name/" /
			rm -r "/data/tmp/$dataset_name/"
			EOF

        # External relation using files on HDFS
        "$SCRIPT_PATH/queries/scripts/create_table.py" \
            --asterixdb-server localhost:19002 \
            --hdfs-server hdfs://namenode:8020 \
            --external-path "/$dataset_name/*.parquet" \
            --dataset-name Run2012B_SingleMu_${n}_untyped_parquet_hdfs \
            --datatype any --file-format parquet --storage-location external \
            --log-level INFO --asterixdb-dataverse IrisHepBenchmark

        # External relation using files on S3
        "$SCRIPT_PATH/queries/scripts/create_table.py" \
            --asterixdb-server localhost:19002 \
            --bucket-name $S3_INPUT_BUCKET \
            --bucket-region $S3_REGION \
            --secret-access-key $S3_SECRET_KEY \
            --access-key-id $S3_ACCESS_KEY \
            --external-path "$dataset_name/" \
            --dataset-name Run2012B_SingleMu_${n}_untyped_parquet_s3 \
            --datatype any --file-format parquet --storage-location external \
            --log-level INFO --asterixdb-dataverse IrisHepBenchmark

    done
) &>> "$deploy_dir/upload_$(date +%F-%H-%M-%S).log"
echo "Done uploading data..."
