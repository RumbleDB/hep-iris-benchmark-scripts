#!/usr/bin/bash

SOURCE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"

$SOURCE_DIR/bigquery.py -i $SOURCE_DIR/bigquery.json -o $SOURCE_DIR/bigquery.pdf
