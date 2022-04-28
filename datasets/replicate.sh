#!/usr/bin/env bash

SOURCE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"

# Load config file
config_file="$SOURCE_DIR/../experiments/common/config.sh"
if ! [ -f "$config_file" ]
then
    echo "Config file config.sh not found." >&2
    exit 1
else
    . "$config_file"
fi

NSF1=53446198

# Replicate data on S3
for l in {1..7}
do
    r=$((2**$l))
    n=$(($sf*$NSF1))
    for i in $(seq -f "%03g" 0 $(($r-1)))
    do
        # Shredded
        #aws s3 cp \
        #    "$S3_INPUT_PATH"/Run2012B_SingleMu_65536000/Run2012B_SingleMu_${NSF1}.parquet \
        #    "$S3_INPUT_PATH"/Run2012B_SingleMu_$n/Run2012B_SingleMu_$n.$i.parquet &

        # Native
        aws s3 cp \
            "$S3_INPUT_PATH"/Run2012B_SingleMu_restructured_65536000/Run2012B_SingleMu_restructured_${NSF1}.parquet \
            "$S3_INPUT_PATH"/Run2012B_SingleMu_restructured_$n/Run2012B_SingleMu_restructured_$n.$i.parquet &
    done
    wait
done

# Replicate data on Google Cloud Storage
for l in {1..7}
do
    sf=$((2**$l))
    n=$(($sf*$NSF1))
    for i in $(seq -f "%03g" 0 $(($sf-1)))
    do
        # Shredded
        #gsutil cp \
        #    "$GS_INPUT_PATH"/Run2012B_SingleMu_65536000/Run2012B_SingleMu_65536000.parquet \
        #    "$GS_INPUT_PATH"/Run2012B_SingleMu_$n/Run2012B_SingleMu_$n.$i.parquet &

        # Native
        gsutil cp \
            "$GS_INPUT_PATH"/Run2012B_SingleMu_restructured_65536000/Run2012B_SingleMu_restructured_65536000.parquet \
            "$GS_INPUT_PATH"/Run2012B_SingleMu_restructured_$n/Run2012B_SingleMu_restructured_$n.$i.parquet &
    done
    wait
done
