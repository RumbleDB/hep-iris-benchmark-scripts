#!/usr/bin/env python3

import argparse

import pandas as pd

parser = argparse.ArgumentParser()
parser.add_argument('-i', '--input',  help='Input CSV file')
parser.add_argument('-o', '--output', help='Output JSON lines file')
args = parser.parse_args()

# Read input
df = pd.read_csv(args.input, sep='\t', header=0)

# Clean up and convert to common schema
df['system'] = 'presto'
df.rename({'query': 'query_id', 'running_time': 'cpu_time'},
          inplace=True, axis='columns')
df.query_id = df.query_id.str.replace('q', '')
df['query_price'] = df.cpu_time / 60 / 60 * 0.226 # $0.226 per Hour

# Write result
df.to_json(args.output, orient='records', lines=True)
