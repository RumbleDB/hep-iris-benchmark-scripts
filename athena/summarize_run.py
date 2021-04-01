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

# Read query statistics
with open(join(run_path, 'query.json'), 'r') as f:
    stats = json.load(f)

# Summarize
data = config.copy()

if 'QueryExecution' in stats:
    stats = stats['QueryExecution']
    assert stats['Status']['State'] == 'SUCCEEDED'
    stats = stats['Statistics']

    data['data_scanned'] = stats.get('DataScannedInBytes', None)
    data['running_time_ms'] = stats.get('TotalExecutionTimeInMillis', None)
    data['queue_time_ms'] = stats.get('QueryQueueTimeInMillis', None)
    data['service_time_ms'] = stats.get('ServiceProcessingTimeInMillis', None)
    data['engine_time_ms'] = stats.get('EngineExecutionTimeInMillis', None)
    data['planning_time_ms'] = stats.get('QueryPlanningTimeInMillis', None)

print(json.dumps(data))
