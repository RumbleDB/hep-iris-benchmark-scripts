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
s=athena;            $SOURCE_DIR/scaling-cpu-time.py -s $s -l    -i $SOURCE_DIR/common.json -o $SOURCE_DIR/scaling-cpu-time-$s.pdf
s=athena-v2;         $SOURCE_DIR/scaling-cpu-time.py -s $s -l -y -i $SOURCE_DIR/common.json -o $SOURCE_DIR/scaling-cpu-time-$s.pdf
s=bigquery;          $SOURCE_DIR/scaling-cpu-time.py -s $s -l -y -i $SOURCE_DIR/common.json -o $SOURCE_DIR/scaling-cpu-time-$s.pdf
s=bigquery-external; $SOURCE_DIR/scaling-cpu-time.py -s $s -l -y -i $SOURCE_DIR/common.json -o $SOURCE_DIR/scaling-cpu-time-$s.pdf
s=presto;            $SOURCE_DIR/scaling-cpu-time.py -s $s -l -y -i $SOURCE_DIR/common.json -o $SOURCE_DIR/scaling-cpu-time-$s.pdf
s=rumble;            $SOURCE_DIR/scaling-cpu-time.py -s $s    -y -i $SOURCE_DIR/common.json -o $SOURCE_DIR/scaling-cpu-time-$s.pdf
