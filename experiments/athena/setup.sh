
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
ROOT_DIR="$SCRIPT_DIR/queries"

ATHENA_DATASET=iris_hep_benchmark
DATA_BUCKET_NAME=iris-hep-benchmark-data
STAGING_DIR=s3://iris-hep-benchmark-data/tmp

for l in {0..16}
do
    n=$((2**$l*1000))

    # Upload "shredded" data
    aws s3 cp \
        "$ROOT_DIR"/data/Run2012B_SingleMu_$n.parquet \
        s3://$DATA_BUCKET_NAME/Run2012B_SingleMu_$n/Run2012B_SingleMu_$n.parquet

    # Upload "native" data
    aws s3 cp \
        "$ROOT_DIR"/data/Run2012B_SingleMu_restructured_$n.parquet \
        s3://$DATA_BUCKET_NAME/Run2012B_SingleMu_restructured_$n/Run2012B_SingleMu_restructured_$n.parquet

    # Create "shredded" table and view
    "$ROOT_DIR"/scripts/create_table.py \
        --variant shredded \
        --database $ATHENA_DATASET \
        --staging-dir $STAGING_DIR \
        --table-name Run2012B_SingleMu_$n \
        --location s3://$DATA_BUCKET_NAME/Run2012B_SingleMu_$n/ \
        --view-name Run2012B_SingleMu_${n}_view

    # Create "native" table
    "$ROOT_DIR"/scripts/create_table.py \
        --variant native \
        --database $ATHENA_DATASET \
        --staging-dir $STAGING_DIR \
        --table-name Run2012B_SingleMu_restructured_$n \
        --location s3://$DATA_BUCKET_NAME/Run2012B_SingleMu_restructured_$n/ \
        --view-name Run2012B_SingleMu_restructured_${n}_view
done
