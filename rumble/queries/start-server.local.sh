#!/bin/bash

cd "$(dirname "${BASH_SOURCE[0]}")"

/path/to/spark/bin/spark-submit \
    /path/to/rumble/target/spark-rumble-1.11.0-jar-with-dependencies.jar \
    --server yes
