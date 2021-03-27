#!/usr/bin/bash

SOURCE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"

s=athena;            $SOURCE_DIR/scaling-running-time.py -s $s -l -x    -i $SOURCE_DIR/common.json -o $SOURCE_DIR/scaling-running-time-$s.pdf
s=athena-v2;         $SOURCE_DIR/scaling-running-time.py -s $s -l -x -y -i $SOURCE_DIR/common.json -o $SOURCE_DIR/scaling-running-time-$s.pdf
s=bigquery;          $SOURCE_DIR/scaling-running-time.py -s $s -l -x -y -i $SOURCE_DIR/common.json -o $SOURCE_DIR/scaling-running-time-$s.pdf
s=bigquery-external; $SOURCE_DIR/scaling-running-time.py -s $s -l -x -y -i $SOURCE_DIR/common.json -o $SOURCE_DIR/scaling-running-time-$s.pdf
s=presto;            $SOURCE_DIR/scaling-running-time.py -s $s -l       -i $SOURCE_DIR/common.json -o $SOURCE_DIR/scaling-running-time-$s.pdf
s=rdataframes;       $SOURCE_DIR/scaling-running-time.py -s $s -l    -y -i $SOURCE_DIR/common.json -o $SOURCE_DIR/scaling-running-time-$s.pdf
s=rumble;            $SOURCE_DIR/scaling-running-time.py -s $s       -y -i $SOURCE_DIR/common.json -o $SOURCE_DIR/scaling-running-time-$s.pdf
