#!/usr/bin/bash

SOURCE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"

$SOURCE_DIR/particle-distribution.py -i $SOURCE_DIR/particle-distribution.csv -o $SOURCE_DIR/particle-distribution.pdf
