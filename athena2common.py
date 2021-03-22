#!/usr/bin/env python3

import argparse

import pandas as pd

parser = argparse.ArgumentParser()
parser.add_argument('-i', '--input',  help='Input JSON lines file')
parser.add_argument('-o', '--output', help='Output JSON lines file')
args = parser.parse_args()

# Read input
df = pd.read_json(args.input, lines=True)

# Clean up and convert to common schema
df.query_id = df.query_id.str.replace('q', '').replace('8-1', '8')
df = df[df.query_id != '8-2']
df.loc[df.num_events == 2**16*1000, 'num_events'] = 53446198
df.loc[df.work_group.fillna('').str.endswith('-v2'), 'system'] = 'athena-v2'

# Interpret running time of "single-row-group" tables as CPU time
singlerowgroup_idx = df.input_table.str.contains('_singlerowgroup_') | \
    df.work_group.isna()  # old runs are single-row-group with different input table name
df.loc[ singlerowgroup_idx, 'cpu_time'] = df.running_time_ms / 1000
df.loc[~singlerowgroup_idx, 'running_time'] = df.running_time_ms / 1000

df['query_price'] = df.data_scanned / 10**12 * 5 # $5.00 per TB
df = df[['system', 'query_id', 'num_events', 'cpu_time', 'running_time',
         'query_price', 'data_scanned']]

# Write result
df.to_json(args.output, orient='records', lines=True)
