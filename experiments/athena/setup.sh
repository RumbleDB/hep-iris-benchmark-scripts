#!/usr/bin/env bash

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
ROOT_DIR="$SCRIPT_DIR/queries"

ATHENA_DATASET=iris_hep_benchmark  # This will have to be created by hand: https://docs.aws.amazon.com/athena/latest/ug/creating-databases.html
DATA_BUCKET_NAME=hep-adl-ethz/artifact-evaluation/parquet/  # Set to your S3 data path
STAGING_DIR=s3://<YOUR-ATHENA-STAGING-AREA> 

NSF1=53446198

for l in {0..16} $NSF1
do
    n=$((2**$l*1000))

    # Create "native" table
    python3 "$ROOT_DIR"/scripts/create_table.py \
        --variant native \
        --database $ATHENA_DATASET \
        --staging-dir $STAGING_DIR \
        --table-name Run2012B_SingleMu_restructured_$n \
        --location s3://$DATA_BUCKET_NAME/Run2012B_SingleMu_restructured_$n/ \
        --view-name Run2012B_SingleMu_restructured_${n}_view
done