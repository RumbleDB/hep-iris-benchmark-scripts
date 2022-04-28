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

# Create bucket
aws s3api create-bucket --region $S3_REGION --bucket $S3_INPUT_BUCKET --create-bucket-configuration "{\"LocationConstraint\":\"$S3_REGION\"}"

# Upload files
for l in {0..16}
do
    n=$((1000*2**$l))
    basename="Run2012B_SingleMu"

    # ROOT
    aws s3 cp "$SOURCE_DIR/${basename}_$n.root" \
              "$S3_INPUT_PATH/${basename}_$n/${basename}_$n.root"

    # Parquet shredded
    #aws s3 cp "$SOURCE_DIR/${basename}_$n.parquet" \
    #          "$S3_INPUT_PATH/${basename}_$n/${basename}_$n.parquet"

    # Parquet native
    aws s3 cp "$SOURCE_DIR/${basename}_restructured_$n.parquet" \
              "$S3_INPUT_PATH/${basename}_restructured_$n/${basename}_restructured_$n.parquet"
done
