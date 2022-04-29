#!/usr/bin/env python3

import argparse
import re

import pandas as pd

parser = argparse.ArgumentParser()
parser.add_argument('-i', '--input',  help='Input JSON lines file')
parser.add_argument('-o', '--output', help='Output JSON lines file')
args = parser.parse_args()

INSTANCE_PRICE_PER_HOUR = {
    'm5d.large': 0.113,
    'm5d.xlarge': 0.226,
    'm5d.2xlarge': 0.452,
    'm5d.4xlarge': 0.904,
    'm5d.8xlarge': 1.808,
    'm5d.12xlarge': 2.712,
    'm5d.16xlarge': 3.616,
    'm5d.24xlarge': 5.424,
}

def num_cores_from_instance_type(s):
    s = re.match('m5[a-z]*\.([0-9]*x?)large', s).group(1)
    if s == '': return 1
    if s == 'x': return 2
    return int(s[:-1]) * 2

# Read input
df = pd.read_json(args.input, lines=True)

# Clean up and convert to common schema
df.query_id = df.query_id \
    .str.replace('query-', '')
df.loc[df.num_events == 2**16*1000, 'num_events'] = 53446198
df['system'] = 'postgres'
df['running_time'] = df.internal_elapsed_time_s
df['instance_type'] = df.instance_type.combine_first(df.vm_type)
df['num_cores'] = df.instance_type.apply(num_cores_from_instance_type)
df.loc[df.num_cores == df.num_cores.min(), 'cpu_time'] = df.running_time
df['query_price'] = \
    df.instance_type.apply(lambda s: INSTANCE_PRICE_PER_HOUR[s]) \
        * df.running_time / 3600
df['data_scanned'] = (df.shared_blks_hit + df.shared_blks_read +
                      df.local_blks_hit + df.local_blks_read) * 8192 + \
                     df.internal_read_bytes

# Project to minimum needed column set
df = df[['system', 'query_id', 'num_events', 'cpu_time', 'running_time',
         'num_cores', 'query_price', 'data_scanned']]

# Write result
df.to_json(args.output, orient='records', lines=True)
