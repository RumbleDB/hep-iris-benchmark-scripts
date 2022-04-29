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
    'm5dn.large': 0.152,
    'm5dn.xlarge': 0.304,
    'm5dn.2xlarge': 0.608,
    'm5dn.4xlarge': 1.216,
    'm5dn.8xlarge': 2.432,
    'm5dn.12xlarge': 3.648,
    'm5dn.16xlarge': 4.866,
    'm5dn.24xlarge': 7.296,
}

# Read input
df = pd.read_json(args.input, lines=True, dtype=False)

# Clean up and convert to common schema
df.loc[df.num_events == 2**16*1000, 'num_events'] = 53446198
df.query_id = df.query_id.str.replace('a', '-1').str.replace('b', '-2')
df['num_cores'] = df.num_instances * df.num_cores_per_instance
df['instance_price_per_hour'] = \
    df.instance_type.apply(lambda s: instance_price_per_hour[s])
df['query_price'] = df.running_time / 60 / 60 * df.instance_price_per_hour
df['data_scanned'] = df.num_sectors_read * 512
df['cpu_time'] = (df.utime + df.stime) / df.clk_tck

# Use IO stats of first (non-cached) iteration for all iterations
df_io = df \
    .groupby(['run_dir']) \
    .aggregate({'data_scanned': 'max'}) \
    .reset_index() \
    .rename({'data_scanned': 'data_scanned_max'}, axis='columns')
df = df.merge(df_io, on=['run_dir'])
df.data_scanned = df.data_scanned_max

df = df[['system', 'query_id', 'num_events', 'cpu_time', 'running_time',
         'query_price', 'data_scanned', 'num_cores']]

# Write result
df.to_json(args.output, orient='records', lines=True)
