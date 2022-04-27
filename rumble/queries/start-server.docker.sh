#!/bin/bash

cd "$(dirname "${BASH_SOURCE[0]}")"

docker run --rm -it \
    -v $PWD:$PWD \
    -p 8001:8001 \
    -p 4040:4040 \
    rumbledb/rumble:v1.11.0-spark3 \
    --server yes --host 0.0.0.0
