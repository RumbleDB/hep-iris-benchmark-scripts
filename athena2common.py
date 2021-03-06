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
df.query_id = df.query_id.str.replace('q', '')
df.loc[df.num_events == 2**16*1000, 'num_events'] = 53446198
df['running_time'] = df.running_time_ms / 1000
df = df[['system', 'query_id', 'num_events', 'running_time']]

# Write result
df.to_json(args.output, orient='records', lines=True)
