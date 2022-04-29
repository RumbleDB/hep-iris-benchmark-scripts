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

df['storage_format'] = df.input_table \
    .apply(lambda s: '_'.join(s.split('_')[3:]))
df['query_id'] = df.query_id.str.replace('query-', '')

# Average over runs
df = df \
    .groupby(['system', 'instance_type', 'num_events',
              'query_id', 'storage_format']) \
    .median().reset_index()

# Plot
fig = plt.figure(figsize=(5.3, 1.8))
ax = fig.add_subplot(1, 1, 1)

if not args.no_yaxis:
    ax.set_ylabel('Running time')
if not args.no_xaxis:
    ax.set_xlabel('Query')

ax.set_yscale('log')

prop_cycle = plt.rcParams['axes.prop_cycle']
colors = prop_cycle.by_key()['color']

styles = {
    'typed_internal':       {'color': colors[1], 'idx': 0, 'label': 'internal (typed)'},
    'untyped_internal':     {'color': colors[2], 'idx': 1, 'label': 'internal (untyped)'},
    'typed_json_hdfs':      {'color': colors[3], 'idx': 3, 'label': 'JSON/HDFS (typed)'},
    'untyped_json_hdfs':    {'color': colors[4], 'idx': 4, 'label': 'JSON/HDFS (untyped)'},
    'typed_json_s3':        {'color': colors[5], 'idx': 5, 'label': 'JSON/S3 (typed)'},
    'untyped_json_s3':      {'color': colors[6], 'idx': 6, 'label': 'JSON/S3 (untyped)'},
    'untyped_parquet_hdfs': {'color': colors[7], 'idx': 2, 'label': 'Parquet/HDFS (untyped)'},
    'untyped_parquet_s3':   {'color': colors[8], 'idx': 2, 'label': 'Parquet/S3 (untyped)'},
}

df['query_label'] = df.query_id \
    .apply(lambda s: 'Q' + s.replace('-1', 'a').replace('-2', 'b'))

formats = sorted(df.storage_format.unique(), key=lambda s: styles[s]['idx'])
num_bars = len(formats)
num_groups = df.query_id.nunique()
bar_width = 0.8 / num_bars
indexes = np.arange(num_groups)
bars = []
for i, sformat in enumerate(formats):
    data_g = df[df.storage_format == sformat]
    data_g = data_g \
        .merge(pd.DataFrame(df.query_id.unique(),
                            columns=['query_id']), how='outer') \
        .sort_values('query_id')
    style = styles[sformat]
    del style['idx']
    handle = ax.bar(indexes - ((num_bars - 1) / 2.0 - i) * bar_width,
                    data_g.running_time, bar_width,
                    tick_label=data_g['query_label'], **style)

ax.set_xticks(indexes)
ax.set_yticks([1, 10, 60, 600, 3600])
ax.set_yticklabels(['1s', '10s', '1m', '10m', '1h'])

if args.no_xaxis:
    ax.set_xticklabels([])

if args.no_yaxis:
    ax.set_yticklabels([])

if not args.no_legend:
    ax.legend(loc='lower center', ncol=3, bbox_to_anchor=(0.5, 1.02))

plt.savefig(args.output, format='pdf', bbox_inches='tight', pad_inches=0)
plt.close()
