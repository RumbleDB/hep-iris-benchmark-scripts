#!/usr/bin/env python3

import argparse

import pandas as pd

parser = argparse.ArgumentParser()
parser.add_argument('-i', '--input',  help='Input CSV file')
parser.add_argument('-o', '--output', help='Output JSON lines file')
args = parser.parse_args()

# Read input
df = pd.read_csv(args.input, sep='\t', header=0)

# Extract input sizes from columns
value_vars = list(df.columns.values)
value_vars = value_vars.remove('query')
df = df.melt(id_vars=['query'], value_vars=value_vars,
             var_name='num_events', value_name='running_time')

# Clean up and convert to common schema
df['system'] = 'rumble'
df.num_events = df.num_events.astype(int)
df.rename({'query': 'query_id'}, inplace=True, axis='columns')

# Write result
df.to_json(args.output, orient='records', lines=True)
