#!/usr/bin/env python3

import argparse
import json
from os.path import join
import re

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

# Read instance information
with open(join(run_path, '..', 'instances.json'), 'r') as f:
    instances = json.load(f)

# Summarize
data = config.copy()

instance_type = None
num_instances = 0
num_cores_per_instance = None
for reservation in instances['Reservations']:
    num_instances += len(reservation['Instances'])

    for instance in reservation['Instances']:
        new_instance_type = instance['InstanceType']
        assert instance_type in [None, new_instance_type]
        instance_type = new_instance_type

        new_num_cores_per_instances = instance['CpuOptions']['CoreCount']
        assert num_cores_per_instance in [None, new_num_cores_per_instances]
        num_cores_per_instance = new_num_cores_per_instances
data['instance_type'] = instance_type
data['num_instances'] = num_instances
data['num_cores_per_instance'] = num_cores_per_instance

timespan = lambda s: round(parse_timespan(s), 6)
METRICS = [
    {'re': '.+ INFO .+ Request ID: ([-0-9a-f]+)$',          'name': 'request_id',           'type': str},
    {'re': '.+ INFO .+ Status: ([a-z]+)$',                  'name': 'status',               'type': str},
    {'re': '.+ INFO .+ Elapsed time: ([0-9.]+[a-z.]+)$',    'name': 'elapsed_time',         'type': timespan},
    {'re': '.+ INFO .+ Execution time: ([0-9.]+[a-z.]+)$',  'name': 'execution_time',       'type': timespan},
    {'re': '.+ INFO .+ Result count: ([0-9]+)$',            'name': 'result_count',         'type': int},
    {'re': '.+ INFO .+ Result size ([0-9]+)$',              'name': 'result_size',          'type': int},
    {'re': '.+ INFO .+ Processed objects: ([0-9]+)$',       'name': 'processed_objects',    'type': int},
    {'re': '.+ INFO .+ Running time: ([0-9.]+)s$',          'name': 'running_time',         'type': float},
]

# Parse run.log
with open(join(run_path, 'run.log'), 'r') as f:
    for line in f.readlines():
        for metric in METRICS:
            m = re.match(metric['re'], line)
            if m:
                metric_name = metric['name']
                assert metric_name not in data
                data[metric_name] = metric['type'](m.group(1))

# Print result
print(json.dumps(data))
