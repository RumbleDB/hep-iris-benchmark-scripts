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
gsutil mb -l $GS_REGION gs://$GS_INPUT_BUCKET

# Upload files
for l in {0..16}
do
    n=$((1000*2**$l))
    basename="Run2012B_SingleMu"

    # Parquet shredded
    #gsutil cp "$SOURCE_DIR/${basename}_$n.parquet" \
    #          "$GS_INPUT_PATH/${basename}_$n/${basename}_$n.parquet"

    # Parquet native
    gsutil cp "$SOURCE_DIR/${basename}_restructured_$n.parquet" \
              "$GS_INPUT_PATH/${basename}_restructured_$n/${basename}_restructured_$n.parquet"
done
