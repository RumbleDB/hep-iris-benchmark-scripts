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

# Parse run.log
last_running_time = None
last_io_stats = None
current_iteration_num = 0
with open(join(run_path, 'run.log'), 'r') as f:
    for line in f.readlines():
        # Try parsing a line from /proc/diskstats of relevant disk
        parts = line.split()
        if len(parts) == 14 and parts[2] == 'md0':
            num_sectors_read =    int(parts[5])
            reading_time =        int(parts[6])
            num_sectors_written = int(parts[9])
            writing_time =        int(parts[10])
            io_time =             int(parts[12])
            io_stats = {
                'num_sectors_read': num_sectors_read,
                'reading_time': reading_time,
                'num_sectors_written': num_sectors_written,
                'writing_time': writing_time,
                'io_time': io_time,
            }

            # If we read a running time previously, we can report the diff to
            # the last diskstats
            if last_running_time:
                d = data.copy()
                d['running_time'] = last_running_time
                d['iteration_num'] = current_iteration_num
                for metric in last_io_stats.keys():
                    d[metric] = io_stats[metric] - last_io_stats[metric]
                print(json.dumps(d))
                current_iteration_num += 1

            # Remember diskstats for next iteration
            last_running_time = None
            last_io_stats = io_stats

        # Try parsing the running time and record it
        m = re.match('^([0-9]+\.[0-9]+) s$', line)
        if m:
            last_running_time = float(m.group(1))
