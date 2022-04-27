#!/usr/bin/env bash

node_id="$(cat /proc/sys/kernel/random/uuid)"
sed -i \
    "s/^node\.id=f\+-f\+-f\+-f\+-f\+\$/node.id=$node_id/" \
    /opt/presto/etc/node.properties
