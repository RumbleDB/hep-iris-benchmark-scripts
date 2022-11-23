#!/usr/bin/env bash

SOURCE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"

# Load config file
config_file="$SOURCE_DIR/../common/config.sh"
if ! [ -f "$config_file" ]
then
    echo "Config file config.sh not found." >&2
    exit 1
else
    . "$config_file"
fi

NSF1=53446198


# Creates an internal table and loads its data
function create_internal {(
    n=$1
    sf=$2
    variant=$3
    basename="Run2012B_SingleMu${variant}"


    # Load data, possibly several times for scale-up
    for _ in $(seq 1 $sf)
    do
        bq load \
            --source_format=PARQUET \
            "$GS_DATASET_ID.${basename}_$n"
            "$GS_INPUT_PATH/${basename}_$n/${basename}_$n.parquet"
    done

    # Create view
    bq mk \
        --use_legacy_sql=false \
        --view "$(sed "s/dataset_id.table_name/$GS_DATASET_ID.${basename}_$n/" "$SOURCE_DIR/queries/view-native.sql")" \
        $GS_DATASET_ID.${basename}_${n}_view
 
)}

# Create and populate internal tables
for variant in "_restructured" # ""
do
    # Scale factor <1
    for l in {0..16}
    do
        n=$((1000*2**$l))
        create_internal $n 1 $variant
    done

    # Scale factor >1
    for l in {0..7}
    do
        sf=$((2**$l))
        n=$(($sf*$NSF1))
        create_internal $n $sf $variant
    done
done
