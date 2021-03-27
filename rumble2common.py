#!/usr/bin/env python3

import argparse

import pandas as pd

parser = argparse.ArgumentParser()
parser.add_argument('-i', '--input',  help='Input JSON lines file')
parser.add_argument('-o', '--output', help='Output JSON lines file')
args = parser.parse_args()

# Read input
df = pd.read_json(args.input, lines=True)

instance_price_per_hour = {
    'm5d.large': 0.113,
    'm5d.xlarge': 0.226,
    'm5d.2xlarge': 0.452,
    'm5d.4xlarge': 0.904,
    'm5d.8xlarge': 1.808,
    'm5d.12xlarge': 2.712,
    'm5d.16xlarge': 3.616,
    'm5d.24xlarge': 5.424,
}
emr_price_per_hour = {
    'm5d.xlarge':   0.057,
    'm5d.2xlarge':  0.113,
    'm5d.4xlarge':  0.226,
    'm5d.8xlarge':  0.27,
    'm5d.12xlarge': 0.27,
    'm5d.16xlarge': 0.27,
    'm5d.24xlarge': 0.27,
}

# Clean up and convert to common schema
df.rename({'runtime': 'running_time',
           'inputRecors': 'num_events',
           'inputBytes': 'data_scanned'},
          inplace=True, axis='columns')
df.VM.fillna('m5d.xlarge', inplace=True)
df.query_id = df.query_id.str.replace('native-objects/query-', '').replace('8-1', '8')
df = df[df.query_id != '8-2']
df['instance_price_per_hour'] = \
    df.VM.apply(lambda s: instance_price_per_hour[s])
df['emr_price_per_hour'] = \
    df.VM.apply(lambda s: emr_price_per_hour[s])
df['query_price'] = df.running_time / 60 / 60 * \
    (df.instance_price_per_hour + df.emr_price_per_hour)

df['num_cores'] = df.VM
df.loc[df.num_cores == 'm5d.large', 'num_cores'] = 'm5d.0.5xlarge'
df.loc[df.num_cores == 'm5d.xlarge', 'num_cores'] = 'm5d.1xlarge'
df['num_cores'] = \
    (df.num_cores
       .str.replace('m5d.', '')
       .str.replace('xlarge', '')
       .astype(float) * 2
    ).astype(int)

df.executorDeserializeCpuTime /= 10**9
df.executorDeserializeTime /= 10**3
df.executorCpuTime /= 10**9
df.executorRunTime /= 10**3
df['cpu_time'] = df.executorDeserializeTime + df.executorRunTime

df = df[['system', 'query_id', 'num_events', 'cpu_time', 'running_time',
         'query_price', 'data_scanned', 'num_cores',
         'executorDeserializeTime', 'executorDeserializeCpuTime',
         'executorRunTime', 'executorCpuTime']]

# Write result
df.to_json(args.output, orient='records', lines=True)
