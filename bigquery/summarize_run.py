#!/usr/bin/env python3

import argparse
import json
from os.path import join

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

# Read job statistics
with open(join(run_path, 'job.json'), 'r') as f:
    stats = json.load(f)

# Summarize
data = config.copy()
data['job_id'] = stats['jobReference']['jobId']
data['job_location'] = stats['jobReference']['location']
data['start_time'] = int(stats['statistics']['startTime'])
data['end_time'] = int(stats['statistics']['endTime'])
data['total_bytes_processed'] = int(stats['statistics']['totalBytesProcessed'])
data['total_bytes_billed'] = int(stats['statistics']['query']['totalBytesBilled'])
data['total_slot_ms'] = int(stats['statistics']['totalSlotMs'])

query_stats = stats['statistics']['query']
data['elapsed_ms'] = int(query_stats['timeline'][-1]['elapsedMs'])

query_plan = query_stats['queryPlan']
assert len(query_plan) == 3
data['completed_parallel_inputs'] = int(query_plan[0]['completedParallelInputs'])
data['input_records_read'] = int(query_plan[0]['recordsRead'])
data['input_slot_ms'] = int(query_plan[0]['slotMs'])

print(json.dumps(data))
