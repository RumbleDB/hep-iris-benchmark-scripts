#!/usr/bin/bash

SOURCE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"

# Convert to common format
$SOURCE_DIR/rumble2common.py   -i $SOURCE_DIR/rumble.csv    -o $SOURCE_DIR/rumble.common.json
$SOURCE_DIR/bigquery2common.py -i $SOURCE_DIR/bigquery.json -o $SOURCE_DIR/bigquery.common.json

# Join files
rm $SOURCE_DIR/common.json
for system in bigquery rumble
do
    cat $SOURCE_DIR/$system.common.json >> $SOURCE_DIR/common.json
    echo >> $SOURCE_DIR/common.json
done

# Plot
s=bigquery;          $SOURCE_DIR/scaling.py -s $s -l    -i $SOURCE_DIR/common.json -o $SOURCE_DIR/scaling-$s.pdf
s=bigquery-external; $SOURCE_DIR/scaling.py -s $s -l -y -i $SOURCE_DIR/common.json -o $SOURCE_DIR/scaling-$s.pdf
s=rumble;            $SOURCE_DIR/scaling.py -s $s    -y -i $SOURCE_DIR/common.json -o $SOURCE_DIR/scaling-$s.pdf
