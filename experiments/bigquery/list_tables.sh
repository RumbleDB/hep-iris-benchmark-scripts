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

# List row count of all tables
bq ls --format=json $GS_DATASET_ID \
    | jq -r '.[].tableReference | (.datasetId + "." + .tableId)' \
    | while read line
    do
        bq query --use_legacy_sql=false \
            "SELECT '$line' AS tablename, COUNT(*) AS num_rows FROM $line"
    done
