#!/bin/bash

docker run --rm \
    -v $PWD:$PWD \
    rumbledb/rumble:v1.11.0-spark3 \
    "$@"
