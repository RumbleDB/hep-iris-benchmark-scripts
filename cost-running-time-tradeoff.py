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
parser.add_argument('-q', '--query',     help='Which query to plot')
parser.add_argument('-l', '--no_legend', help='Suppress legend from plot',
                                         action='store_true')
parser.add_argument('-x', '--no_xaxis',  help='Suppress x-axis from plot',
                                         action='store_true')
parser.add_argument('-y', '--no_yaxis',  help='Suppress y-axis from plot',
                                         action='store_true')
args = parser.parse_args()

df = pd.read_json(args.input, lines=True)
df.loc[df.num_cores.isna(), 'num_cores'] = 0
df = df[df.query_id == args.query]

df = df[(df.system != 'presto') | (df.num_cores != 0)]
df = df[df.system != 'athena'] # exclude Athena v1, which reports bogus numbers

# Average over runs
df = df.groupby(['system', 'query_id', 'num_events', 'num_cores']).median().reset_index()

# Extrapolate to full data set
df_max_size = df[~df.running_time.isna()] \
    .groupby(['system', 'query_id', 'num_cores']) \
    .agg({'num_events': 'max'}) \
    .reset_index()

df = df.merge(df_max_size, on=['system', 'query_id', 'num_events', 'num_cores'])

df['extrapolated_query_price'] = \
    df.query_price / df.num_events * df.num_events.max()
df['extrapolated_query_price_ct'] = df.extrapolated_query_price * 100
df['extrapolated_running_time'] = \
    df.running_time / df.num_events * df.num_events.max()
df.sort_values(by=['num_cores'], inplace=True)

fig = plt.figure(figsize=(2.3, 1.8))
ax = fig.add_subplot(1, 1, 1)

if not args.no_yaxis:
    ax.set_ylabel('Running time')
if not args.no_xaxis:
    ax.set_xlabel('Cost')

ax.set_xscale('log')
ax.set_yscale('log')

prop_cycle = plt.rcParams['axes.prop_cycle']
colors = prop_cycle.by_key()['color']

styles = {
    'athena':            {'color': colors[0], 'marker': 'p', 'markersize': 5, 'label': 'Athena (v1)', 'markerfacecolor': 'white'},
    'athena-v2':         {'color': colors[1], 'marker': '*', 'markersize': 7, 'label': 'Athena (v2)'},
    'bigquery':          {'color': colors[2], 'marker': '^', 'markersize': 5, 'label': 'BigQuery'},
    'bigquery-external': {'color': colors[3], 'marker': 'v', 'markersize': 5, 'label': 'BigQuery\n(external)'},
    'presto':            {'color': colors[4], 'marker': 'o', 'markersize': 3, 'label': 'Presto', 'zorder': 0},
    'rumble':            {'color': ETHa,      'marker': 'x', 'markersize': 3, 'label': 'Rumble'},
}

for i, system in enumerate(sorted(df.system.unique())):
    data_g = df[df.system == system]
    ax.plot(data_g.extrapolated_query_price_ct, data_g.extrapolated_running_time,
            **styles[system])

ax.set_xlim(0.1, 100)
ax.set_xticks([0.1, 1, 10, 100])
ax.set_xticklabels(['0.1¢', '1¢', '10¢', '1$'])
ax.set_ylim(0.1, 60*60)
ax.set_yticks([0.1, 1, 10, 60, 10*60, 60*60])
ax.set_yticklabels(['.1s', '1s', '10s', '1m', '10m', '1h'])

if args.no_xaxis:
    ax.set_xticklabels([])

if args.no_yaxis:
    ax.set_yticklabels([])

if not args.no_legend:
    ax.legend(loc='center left', bbox_to_anchor=(1.02, 0.5))

plt.savefig(args.output, format='pdf', bbox_inches='tight', pad_inches=0)
plt.close()
