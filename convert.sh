#!/usr/bin/bash

SOURCE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"

# Convert to common format
$SOURCE_DIR/athena2common.py      -i $SOURCE_DIR/athena.json      -o $SOURCE_DIR/athena.common.json
$SOURCE_DIR/bigquery2common.py    -i $SOURCE_DIR/bigquery.json    -o $SOURCE_DIR/bigquery.common.json
$SOURCE_DIR/presto2common.py      -i $SOURCE_DIR/presto.json      -o $SOURCE_DIR/presto.common.json
$SOURCE_DIR/rdataframes2common.py -i $SOURCE_DIR/rdataframes.json -o $SOURCE_DIR/rdataframes.common.json
$SOURCE_DIR/rumble2common.py      -i $SOURCE_DIR/rumble.csv       -o $SOURCE_DIR/rumble.common.json

# Join files
rm $SOURCE_DIR/common.json
for system in athena bigquery presto rdataframes rumble
do
    cat $SOURCE_DIR/$system.common.json >> $SOURCE_DIR/common.json
    echo >> $SOURCE_DIR/common.json
done
