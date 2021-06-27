#!/usr/bin/bash

SOURCE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"

"$SOURCE_DIR/asterixdb-format-tuning.py" -i "$SOURCE_DIR/asterixdb-format-tuning.json" -o "$SOURCE_DIR/asterixdb-format-tuning.pdf"
