#!/usr/bin/bash

SOURCE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"

# Convert to common format
$SOURCE_DIR/athena2common.py   -i $SOURCE_DIR/athena.json   -o $SOURCE_DIR/athena.common.json
$SOURCE_DIR/bigquery2common.py -i $SOURCE_DIR/bigquery.json -o $SOURCE_DIR/bigquery.common.json
$SOURCE_DIR/presto2common.py   -i $SOURCE_DIR/presto.csv    -o $SOURCE_DIR/presto.common.json
$SOURCE_DIR/rumble2common.py   -i $SOURCE_DIR/rumble.csv    -o $SOURCE_DIR/rumble.common.json

# Join files
rm $SOURCE_DIR/common.json
for system in athena bigquery presto rumble
do
    cat $SOURCE_DIR/$system.common.json >> $SOURCE_DIR/common.json
    echo >> $SOURCE_DIR/common.json
done

# Plot
$SOURCE_DIR/systems-running-time.py  -l -x -i $SOURCE_DIR/common.json -o $SOURCE_DIR/systems-running-time.pdf
$SOURCE_DIR/systems-cpu-time.py      -l -x -i $SOURCE_DIR/common.json -o $SOURCE_DIR/systems-cpu-time.pdf
$SOURCE_DIR/systems-data-scanned.py     -x -i $SOURCE_DIR/common.json -o $SOURCE_DIR/systems-data-scanned.pdf
$SOURCE_DIR/systems-price.py         -l    -i $SOURCE_DIR/common.json -o $SOURCE_DIR/systems-price.pdf
