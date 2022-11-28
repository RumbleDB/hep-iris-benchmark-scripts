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

# Create dataset
bq --location=$GS_REGION \
    mk --dataset \
       --description "IRIS HEP Benchmark Data" \
       $GS_DATASET_ID

# Creates an external table
function create_external {(
    n=$1
    variant=$2

    basename="Run2012B_SingleMu${variant}"

    # Create external table
    table_def_file="$(mktemp)"
    cat > "$table_def_file" <<-EOF
	{
	  "sourceFormat": "PARQUET",
	  "sourceUris": [
	     "$GS_INPUT_PATH/${basename}_$n/${basename}_$n.parquet"
	  ]
	}
	EOF

    bq mk \
        --external_table_definition="$table_def_file" \
        "$GS_DATASET_ID.${basename}_external_$n"
    rm "$table_def_file"

    # Create view
    bq mk \
        --use_legacy_sql=false \
        --view "$(sed "s/dataset_id.table_name/$GS_DATASET_ID.${basename}_external_$n/" "$SOURCE_DIR/queries/view-native.sql")" \
        "$GS_DATASET_ID.${basename}_external_${n}_view"
)}

# Create external tables
for variant in "_restructured" # ""
do
    # Scale factor <1
    for l in {0..16}
    do
        n=$((1000*2**$l))
        create_external $n $variant
    done

    # Scale factor >1
    for l in {0..7}
    do
        sf=$((2**$l))
        n=$(($sf*$NSF1))
        create_external $n $variant
    done
done
