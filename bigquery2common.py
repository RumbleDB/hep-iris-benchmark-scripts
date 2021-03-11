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
df.num_events = df.input_records_read
df.query_id = df.query_id.str.replace('queries/query-', '')
df.loc[df.input_table.str.contains('_external_'), 'system'] = 'bigquery-external'
df['cpu_time'] = df.total_slot_ms / 1000
df['running_time'] = df.elapsed_ms / 1000
df['query_price'] = df.total_bytes_billed / 10**12 * 5 # $5.00 per TB
df['data_scanned'] = df.total_bytes_billed

df = df[['system', 'query_id', 'num_events', 'cpu_time', 'running_time',
         'query_price', 'data_scanned']]

# Write result
df.to_json(args.output, orient='records', lines=True)
