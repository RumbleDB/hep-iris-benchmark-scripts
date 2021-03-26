#!/usr/bin/env python3

import argparse
import json
from os.path import join
import re

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

# Read run.log
with open(join(run_path, 'run.log'), 'r') as f:
    for line in f.readlines():
        m = re.match('^([0-9]+\.[0-9]+) s$', line)
        if m:
            d = data.copy()
            d['running_time'] = float(m.group(1))
            print(json.dumps(d))
