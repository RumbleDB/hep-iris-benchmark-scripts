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
state = {}
data['cpu_stats'] = {}
data['net_stats'] = {}
with open(join(run_path, 'run.log'), 'r') as f:
    for line in f.readlines():
        # Parse metrics from test_queries.py
        for metric in METRICS:
            m = re.match(metric['re'], line)
            if m:
                metric_name = metric['name']
                assert metric_name not in data
                data[metric_name] = metric['type'](m.group(1))
                break
        if m: continue

        # Parse any line from kernel stats
        m = re.match('^([0-9]+)\|.*', line)
        if m:
            if m.group(1) not in state:
                state[m.group(1)] = {}

        # Parse CLK_TCK
        m = re.match('^([0-9]+)\|CLK_TCK: ([0-9]+)', line)
        if m:
            clk_tck = int(m.group(2))
            if 'CLK_TCK' in state[m.group(1)]:
                assert state[m.group(1)]['CLK_TCK'] == clk_tck
            state[m.group(1)]['CLK_TCK'] = clk_tck
            continue

        # Parse CPU stats
        m = re.match('^([0-9]+)\|(([^ ]+ ){51}([^ ]+))', line)
        if m:
            node_id = m.group(1)

            parts = m.group(2).split(' ')
            cpu_stats = {
                'minflt':  int(parts[9]),
                'cminflt': int(parts[10]),
                'majflt':  int(parts[11]),
                'cmajflt': int(parts[12]),
                'utime':   int(parts[13]),
                'stime':   int(parts[14]),
                'cutime':  int(parts[15]),
                'cstime':  int(parts[16]),
            }
            pid = parts[0]

            if 'cpu_stats' not in state[node_id]:
                state[node_id]['cpu_stats'] = {}

            if pid not in state[node_id]['cpu_stats']:
                state[node_id]['cpu_stats'][pid] = cpu_stats
            else:
                last_cpu_stats = state[node_id]['cpu_stats'][pid]
                metrics = {}
                for metric in cpu_stats.keys():
                    metrics[metric] = cpu_stats[metric] - last_cpu_stats[metric]
                if node_id not in data['cpu_stats']:
                    data['cpu_stats'][node_id] = {}
                data['cpu_stats'][node_id][pid] = metrics
                data['cpu_stats'][node_id][pid]['CLK_TCK'] = state[node_id]['CLK_TCK']
            continue

        # Parse CPU stats
        m = re.match('^([0-9]+)\|eth0:(( +[0-9]+){16})', line)
        if m:
            node_id = m.group(1)

            parts = re.split(' +', m.group(2).strip())
            net_stats = {
                'rx_bytes':         int(parts[0]),
                'rx_packets':       int(parts[1]),
                'rx_errs':          int(parts[2]),
                'rx_drop':          int(parts[3]),
                'rx_fifo':          int(parts[4]),
                'rx_frame':         int(parts[5]),
                'rx_compressed':    int(parts[6]),
                'rx_multicast':     int(parts[7]),
                'tx_bytes':         int(parts[8]),
                'tx_packets':       int(parts[9]),
                'tx_errs':          int(parts[10]),
                'tx_drop':          int(parts[11]),
                'tx_fifo':          int(parts[12]),
                'tx_colls':         int(parts[13]),
                'tx_carrier':       int(parts[14]),
                'tx_compressed':    int(parts[15]),
            }

            if 'net_stats' not in state[node_id]:
                state[node_id]['net_stats'] = net_stats
            else:
                last_net_stats = state[node_id]['net_stats']
                metrics = {}
                for metric in net_stats.keys():
                    metrics[metric] = net_stats[metric] - last_net_stats[metric]
                data['net_stats'][node_id] = metrics
            continue

# Print result
print(json.dumps(data))
