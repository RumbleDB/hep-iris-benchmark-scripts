#!/usr/bin/env python3

import argparse

import pandas as pd

parser = argparse.ArgumentParser()
parser.add_argument('-i', '--input',  help='Input JSON lines file')
parser.add_argument('-o', '--output', help='Output JSON lines file')
args = parser.parse_args()

INSTANCE_PRICE_PER_HOUR = {
    'm5d.large': 0.113,
    'm5d.xlarge': 0.226,
    'm5d.2xlarge': 0.452,
    'm5d.4xlarge': 0.904,
    'm5d.8xlarge': 1.808,
    'm5d.12xlarge': 2.712,
    'm5d.16xlarge': 3.616,
    'm5d.24xlarge': 5.424,
}

# Read input
df = pd.read_json(args.input, lines=True)

def summarize_cpu_stats(stats):
    res = {}
    clk_tck = None
    for node_id, node_stats in stats.items():
        for pid, pid_stats in node_stats.items():
            assert clk_tck is None or clk_tck == pid_stats['CLK_TCK']
            clk_tck = pid_stats['CLK_TCK']
            for metric in pid_stats:
                if metric not in res:
                    res[metric] = 0
                res[metric] += pid_stats[metric]
    res['CLK_TCK'] = clk_tck
    return res

def summarize_net_stats(stats):
    res = {}
    for node_id, node_stats in stats.items():
        for metric in node_stats:
            if metric not in res:
                res[metric] = 0
            res[metric] += node_stats[metric]
    return res

# Clean up and convert to common schema
df.loc[df.num_events == 2**16*1000, 'num_events'] = 53446198

assert (df.num_events == df.processed_objects).all()
assert (df.status == 'success').all()

df.query_id = df.query_id.str.replace('query-', '')

df['instance_price_per_hour'] = \
    df.instance_type.apply(lambda s: INSTANCE_PRICE_PER_HOUR[s])
df['query_price'] = df.running_time / 60 / 60 * df.instance_price_per_hour
df['num_cores'] = df.num_instances * df.num_cores_per_instance

df['total_cpu_stats'] = df.cpu_stats.apply(summarize_cpu_stats)
df['total_net_stats'] = df.net_stats.apply(summarize_net_stats)

df['clk_tck'] = df.total_cpu_stats.apply(lambda d: d['CLK_TCK'])
df['cpu_time'] = df.total_cpu_stats \
    .apply(lambda d: d['utime'] + d['stime']) / df.clk_tck
df['rx_bytes'] = df.total_net_stats.apply(lambda d: d['rx_bytes'])
df['data_scanned'] = df[['rx_bytes']][df.input_table.str.endswith('_s3')]

df = df[['system', 'query_id', 'num_events', 'cpu_time', 'running_time',
         'query_price', 'data_scanned', 'num_cores']]

# Write result
df.to_json(args.output, orient='records', lines=True)
