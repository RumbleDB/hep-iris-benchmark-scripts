#!/usr/bin/env python3

import argparse

import pandas as pd

parser = argparse.ArgumentParser()
parser.add_argument('-i', '--input',  help='Input JSON file')
parser.add_argument('-o', '--output', help='Output JSON lines file')
args = parser.parse_args()

# Read input
df = pd.read_json(args.input, lines=True)

# Clean up and convert to common schema
df['system'] = 'presto'
df.num_events = df.records_scanned
df.rename({'elapsed_time': 'running_time',
           'bytes_scanned': 'data_scanned',
           'total_cpu_time': 'cpu_time'},
          inplace=True, axis='columns')
df.query_id = df.query_id.str.replace('q', '')
df['query_price'] = df.cpu_time / 60 / 60 * 0.226 # $0.226 per Hour

df = df[['system', 'query_id', 'num_events', 'cpu_time', 'running_time',
         'query_price', 'data_scanned']]

# Write result
df.to_json(args.output, orient='records', lines=True)
