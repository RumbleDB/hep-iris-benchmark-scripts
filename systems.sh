#!/usr/bin/bash

SOURCE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"

$SOURCE_DIR/systems-cpu-time.py        -l -x -i $SOURCE_DIR/common.json -o $SOURCE_DIR/systems-cpu-time.pdf
$SOURCE_DIR/systems-data-scanned.py       -x -i $SOURCE_DIR/common.json -o $SOURCE_DIR/systems-data-scanned.pdf
$SOURCE_DIR/systems-scan-throughput.py -l    -i $SOURCE_DIR/common.json -o $SOURCE_DIR/systems-scan-throughput.pdf

$SOURCE_DIR/systems-running-time.py       -x -i $SOURCE_DIR/common.json -o $SOURCE_DIR/systems-running-time.pdf
$SOURCE_DIR/systems-price.py           -l    -i $SOURCE_DIR/common.json -o $SOURCE_DIR/systems-price.pdf
