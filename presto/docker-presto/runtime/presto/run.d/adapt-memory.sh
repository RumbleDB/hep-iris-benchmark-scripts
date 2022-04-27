#!/usr/bin/env bash

MEMORY_PERCENT_HEAP=75
MEMORY_PERCENT_MAX=55
MEMORY_PERCENT_MAX_TOTAL=69

available_mem_kb=$(sed -n 's/MemTotal: *\([0-9]\+\) kB/\1/p' /proc/meminfo)
available_mem=$(($available_mem_kb*1000))
target_heap=$(($available_mem*$MEMORY_PERCENT_HEAP/100))
target_max=$(($target_heap*$MEMORY_PERCENT_MAX/100))
target_max_total=$(($target_heap*$MEMORY_PERCENT_MAX_TOTAL/100))

sed -i \
    "s/^-Xmx16G\$/-Xmx$target_heap/" \
    /opt/presto/etc/jvm.config

cat - >> /opt/presto/etc/config.properties <<-EOF
	query.max-memory-per-node=${target_max}B
	query.max-total-memory-per-node=${target_max_total}B
	EOF
