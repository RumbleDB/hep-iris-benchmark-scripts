#!/usr/bin/env python3

import argparse

import pandas as pd

parser = argparse.ArgumentParser()
parser.add_argument('-i', '--input',  help='Input JSON file')
parser.add_argument('-o', '--output', help='Output JSON lines file')
args = parser.parse_args()

instance_price_per_hour = {
    'm5d.large': 0.113,
    'm5d.xlarge': 0.226,
    'm5d.2xlarge': 0.452,
    'm5d.4xlarge': 0.904,
    'm5d.8xlarge': 1.808,
    'm5d.12xlarge': 2.712,
    'm5d.16xlarge': 3.616,
    'm5d.24xlarge': 5.424,
}

# Read input
df = pd.read_json(args.input, lines=True)

# Clean up and convert to common schema
df['system'] = 'presto'
df.num_events = df.records_scanned
df.loc[df.instance_type.isna(), 'instance_type'] = 'm5d.xlarge'
df.loc[df.num_events == 2**16*1000, 'num_events'] = 53446198
df['num_cores'] = df.num_instances * df.num_cores_per_instance
df.rename({'elapsed_time': 'running_time',
           'bytes_scanned': 'data_scanned',
           'total_cpu_time': 'cpu_time'},
          inplace=True, axis='columns')
df['instance_price_per_hour'] = \
    df.instance_type.apply(lambda s: instance_price_per_hour[s])
df.query_id = df.query_id.str.replace('q', '').replace('8-1', '8')
df = df[df.query_id != '8-2']
df['query_price'] = df.running_time / 60 / 60 * df.instance_price_per_hour

df = df[['system', 'query_id', 'num_events', 'cpu_time', 'running_time',
         'query_price', 'data_scanned', 'num_cores']]

# Write result
df.to_json(args.output, orient='records', lines=True)
