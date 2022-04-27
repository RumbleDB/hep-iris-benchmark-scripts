#!/usr/bin/env bash

docker run --rm -i ingomuellernet/presto:0.258 presto-cli "$@"
