#!/usr/bin/env bash

SCRIPT_PATH="$( cd "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"
ENABLE_JSON_DATA_COPY=false

# Load common functions
. "$SCRIPT_PATH/../common/ec2-helpers.sh"

# Find deploy directory
experiments_dir="$SCRIPT_PATH/../experiments"
deploy_dir="$(discover_cluster "$experiments_dir")"
dnsnames=($(discover_dnsnames "$deploy_dir"))

# Upload data
echo "Uploading data..."
(
    for dnsname in ${dnsnames[@]}
    do
        ssh -q ec2-user@$dnsname \
            mkdir -p /data/input
    done

    NSF1=53446198

    #
    # Copy data into instance
    #

    for n in $(for l in {0..16}; do echo $((2**$l*1000)); done) $NSF1
    do
        # Copy JSON data from S3 to HDFS
        if [ "${ENABLE_JSON_DATA_COPY}" = true ]; then
            dataset_name="Run2012B_SingleMu_restructured_json_${n}"

            ssh -q ec2-user@${dnsnames[0]} \
                <<-EOF
				mkdir -p /data/tmp
				aws s3 cp --no-progress --recursive "$S3_INPUT_PATH/$dataset_name/" "/data/tmp/$dataset_name/"
				./hadoop/bin/hadoop fs -mkdir "/$dataset_name"
				./hadoop/bin/hadoop fs -put "/data/tmp/$dataset_name/" /
				rm -r "/data/tmp/$dataset_name/"
				EOF

            for dnsname in ${dnsnames[@]}
            do
                ssh -q ec2-user@$dnsname \
                    aws s3 cp --no-progress --recursive "$S3_INPUT_PATH/$dataset_name/" "/data/input/$dataset_name/"
            done
        fi

        dataset_name="Run2012B_SingleMu_restructured_${n}"

        # Copy Parquet data from S3 to disk
        for dnsname in ${dnsnames[@]}
        do
            ssh -q ec2-user@$dnsname \
                aws s3 cp --no-progress --recursive "$S3_INPUT_PATH/$dataset_name/" "/data/input/$dataset_name/"
        done

        # Copy Parquet data from S3 to HDFS
        ssh -q ec2-user@${dnsnames[0]} \
            <<-EOF
			mkdir -p /data/tmp
			aws s3 cp --no-progress --recursive "$S3_INPUT_PATH/$dataset_name/" "/data/tmp/$dataset_name/"
			./hadoop/bin/hadoop fs -mkdir "/$dataset_name"
			./hadoop/bin/hadoop fs -put "/data/tmp/$dataset_name/" /
			rm -r "/data/tmp/$dataset_name/"
			EOF
    done

    #
    # Replicate
    #

    for sf in $(for l in {0..7}; do echo $((2**$l)); done)
    do
        :
    done

    #
    # Create tables
    #

    for n in $(for l in {0..15}; do echo $((2**$l*1000)); done) \
             $(for l in {0..7};  do echo $((2**$l*$NSF1)); done)
    do

        #
        # JSON
        #

        if [ "${ENABLE_JSON_DATA_COPY}" = true ]; then 
            dataset_name="Run2012B_SingleMu_restructured_json_${n}"

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

            # External relations using local files
            "$SCRIPT_PATH/queries/scripts/create_table.py" \
                --asterixdb-server localhost:19002 \
                --external-path "file:///data/input/$dataset_name/*.json.gz" \
                --dataset-name Run2012B_SingleMu_${n}_untyped_json_local \
                --datatype any --file-format json --storage-location external \
                --log-level INFO --asterixdb-dataverse IrisHepBenchmark

            "$SCRIPT_PATH/queries/scripts/create_table.py" \
                --asterixdb-server localhost:19002 \
                --external-path "file:///data/input/$dataset_name/*.json.gz" \
                --dataset-name Run2012B_SingleMu_${n}_typed_json_local \
                --datatype event --file-format json --storage-location external \
                --log-level INFO --asterixdb-dataverse IrisHepBenchmark
            fi

        #
        # Parquet
        #

        dataset_name="Run2012B_SingleMu_restructured_${n}"

        # External relation using local files
        "$SCRIPT_PATH/queries/scripts/create_table.py" \
            --asterixdb-server localhost:19002 \
            --external-path "file:///data/input/$dataset_name/*.parquet" \
            --dataset-name Run2012B_SingleMu_${n}_untyped_parquet_local \
            --datatype any --file-format parquet --storage-location external \
            --log-level INFO --asterixdb-dataverse IrisHepBenchmark

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
