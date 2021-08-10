#!/usr/bin/bash

SOURCE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"

s=asterixdb;         $SOURCE_DIR/scaling-running-time.py -s $s -l -x    -i $SOURCE_DIR/common.json -o $SOURCE_DIR/scaling-running-time-$s.pdf
s=athena;            $SOURCE_DIR/scaling-running-time.py -s $s -l -x -y -i $SOURCE_DIR/common.json -o $SOURCE_DIR/scaling-running-time-$s.pdf
s=athena-v2;         $SOURCE_DIR/scaling-running-time.py -s $s -l -x -y -i $SOURCE_DIR/common.json -o $SOURCE_DIR/scaling-running-time-$s.pdf
s=bigquery;          $SOURCE_DIR/scaling-running-time.py -s $s -l -x -y -i $SOURCE_DIR/common.json -o $SOURCE_DIR/scaling-running-time-$s.pdf
s=bigquery-external; $SOURCE_DIR/scaling-running-time.py -s $s -l       -i $SOURCE_DIR/common.json -o $SOURCE_DIR/scaling-running-time-$s.pdf
s=postgres;          $SOURCE_DIR/scaling-running-time.py -s $s -l    -y -i $SOURCE_DIR/common.json -o $SOURCE_DIR/scaling-running-time-$s.pdf
s=presto;            $SOURCE_DIR/scaling-running-time.py -s $s -l    -y -i $SOURCE_DIR/common.json -o $SOURCE_DIR/scaling-running-time-$s.pdf
s=rdataframes;       $SOURCE_DIR/scaling-running-time.py -s $s -l    -y -i $SOURCE_DIR/common.json -o $SOURCE_DIR/scaling-running-time-$s.pdf
s=rumble;            $SOURCE_DIR/scaling-running-time.py -s $s -l    -y -i $SOURCE_DIR/common.json -o $SOURCE_DIR/scaling-running-time-$s.pdf
s=legend;            $SOURCE_DIR/scaling-running-time.py       -L       -i $SOURCE_DIR/common.json -o $SOURCE_DIR/scaling-running-time-$s.pdf
