#!/usr/bin/env python3

import argparse
import json
from os.path import join

from humanfriendly import parse_size, parse_timespan

# Parse CLI arguments
parser = argparse.ArgumentParser(
    description='Summarize data of individual query run.',
)
parser.add_argument('run-path', help='Path to the data collected for this run.')
args = parser.parse_args()

run_path = vars(args)['run-path']

# Read config
with open(join(run_path, 'config.json'), 'r') as f:
    config = json.load(f)

# Read query statistics
with open(join(run_path, 'query.json'), 'r') as f:
    stats = json.load(f)

# Summarize
data = config.copy()

if isinstance(stats, dict) and stats['state'] == 'FINISHED':
    stats = stats['queryStats']

    # Top-level metrics
    data['elapsed_time'] =   round(parse_timespan(stats['elapsedTime']), 6)
    data['total_cpu_time'] = round(parse_timespan(stats['totalCpuTime']), 6)
    data['bytes_scanned'] = parse_size(stats['rawInputDataSize'])
    data['records_scanned'] = stats['rawInputPositions']

    # Summarize exchange operators
    num_exchange = 0
    bytes_exchanged = 0
    records_exchanged = 0
    for op in stats['operatorSummaries']:
        if op['operatorType'] == 'ExchangeOperator':
            num_exchange += 1
            records_exchanged += op['rawInputPositions']
            bytes_exchanged += parse_size(op['rawInputDataSize'])
    data['num_exchange'] = num_exchange
    data['records_exchanged'] = records_exchanged
    data['bytes_exchanged'] = bytes_exchanged

# Print result
print(json.dumps(data))
