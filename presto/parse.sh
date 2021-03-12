#!/usr/bin/env bash

SOURCE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"

lastexp=$(ls -d "$SOURCE_DIR"/experiments/experiment_* | sort | tail -n1)
make -f "$SOURCE_DIR"/parse.mk -C $lastexp
