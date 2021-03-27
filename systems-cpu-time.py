#!/usr/bin/env python3

import argparse
import matplotlib; matplotlib.use('Agg')
import numpy as np
import pandas as pd
from matplotlib import pyplot as plt

plt.rcParams.update({
    'errorbar.capsize': 2,
    'pdf.fonttype': 42,
    'ps.fonttype': 42,
    'font.family': 'Linux Libertine',
})

ETHa = ( 31/255,  64/255, 122/255) # dark blue
ETHb = ( 72/255,  90/255,  44/255) # dark green
ETHc = ( 18/255, 105/255, 176/255) # light blue
ETHd = (114/255, 121/255,  28/255) # light green
ETHe = (145/255,   5/255, 106/255) # dark pink
ETHf = (111/255, 111/255, 100/255) # gray
ETHg = (168/255,  50/255,  45/255) # dark red
ETHh = (  0/255, 122/255, 150/255) # turquoise
ETHi = (149/255,  96/255,  19/255) # brown

parser = argparse.ArgumentParser()
parser.add_argument('-i', '--input',     help='Input JSON lines file')
parser.add_argument('-o', '--output',    help='Output PDF file')
parser.add_argument('-l', '--no_legend', help='Suppress legend from plot',
                                         action='store_true')
parser.add_argument('-x', '--no_xaxis',  help='Suppress x-axis from plot',
                                         action='store_true')
parser.add_argument('-y', '--no_yaxis',  help='Suppress y-axis from plot',
                                         action='store_true')
args = parser.parse_args()

df = pd.read_json(args.input, lines=True)

df = df[df.cpu_time.notna()]
df = df[df.query_id != '6']
df.loc[df.num_cores.isna(), 'num_cores'] = 0

# Average over runs
df = df.groupby(['system', 'num_cores', 'query_id', 'num_events']).median().reset_index()

# Extrapolate to full data set
df_max_data = df\
    .groupby(['system', 'num_cores', 'query_id']) \
    .agg({'num_events': 'max'}) \
    .reset_index()
df = df.merge(df_max_data, on=['system', 'num_cores', 'query_id', 'num_events'])

# Use best configuration for RDataFrames
df = df[(df.system != 'rdataframes') | (df.num_cores == 24)]

# Use largest configurations for everything else
df_max_cluster = df\
    .groupby(['system', 'query_id']) \
    .agg({'num_cores': 'max'}) \
    .reset_index()
df = df.merge(df_max_cluster, on=['system', 'num_cores', 'query_id'])

df['cpu_time_per_event'] = df.cpu_time / df.num_events
df['cpu_time_per_event_us'] = df.cpu_time_per_event * 10**6
df['extrapolated_cpu_time'] = \
    df.cpu_time_per_event * df.num_events.max()

# Plot
fig = plt.figure(figsize=(5.3, 1.8))
ax = fig.add_subplot(1, 1, 1)

if not args.no_yaxis:
    ax.set_ylabel('CPU time per event')
if not args.no_xaxis:
    ax.set_xlabel('Query')

ax.set_yscale('log')

prop_cycle = plt.rcParams['axes.prop_cycle']
colors = prop_cycle.by_key()['color']

styles = {
    'athena':            {'color': colors[0], 'label': 'Athena (v1)*'},
    'athena-v2':         {'color': colors[1], 'label': 'Athena (v2)*'},
    'bigquery':          {'color': colors[2], 'label': 'BigQuery'},
    'bigquery-external': {'color': colors[3], 'label': 'BigQuery (external)'},
    'presto':            {'color': colors[4], 'label': 'Presto'},
    'rdataframes':       {'color': colors[5], 'label': 'RDataFrames'},
    'rumble':            {'color': ETHa,      'label': 'Rumble'},
}

df['query_label'] = df.query_id \
    .apply(lambda s: 'Q' + s.replace('-1', 'a').replace('-2', 'b'))

systems = sorted(df.system.unique(), key=lambda s: styles[s]['label'])
num_bars = len(systems)
num_groups = df.query_id.nunique()
bar_width = 0.8 / num_bars
indexes = np.arange(num_groups)
bars = []
for i, system in enumerate(systems):
    data_g = df[df.system == system]
    data_g = data_g \
        .merge(pd.DataFrame(df.query_id.unique(),
                            columns=['query_id']), how='outer') \
        .sort_values('query_id')
    handle = ax.bar(indexes - ((num_bars - 1) / 2.0 - i) * bar_width,
                    data_g.cpu_time_per_event_us, bar_width,
                    tick_label=data_g['query_label'],
                    **styles[system])

ax.set_xticks(indexes)
ax.set_yticks([.1, 1, 10, 100, 1000, 10000])
ax.set_yticklabels(['.1μs', '1μs', '10μs', '.1ms', '1ms', '10ms'])

if args.no_xaxis:
    ax.set_xticklabels([])

if args.no_yaxis:
    ax.set_yticklabels([])

if not args.no_legend:
    ax.legend(loc='lower center', ncol=3, bbox_to_anchor=(0.5, 1.02))

plt.savefig(args.output, format='pdf', bbox_inches='tight', pad_inches=0)
plt.close()
