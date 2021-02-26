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
df['total_slot'] = df.total_slot_ms / 1000

# Average over runs
df = df.groupby(['system', 'query_id', 'input_records_read']).median().reset_index()

fig = plt.figure(figsize=(2.3, 1.8))
ax = fig.add_subplot(1, 1, 1)

if not args.no_yaxis:
    ax.set_ylabel('Running time')
if not args.no_xaxis:
    ax.set_xlabel('Input size [#events]')

ax.set_xscale('log')
ax.set_yscale('log')

prop_cycle = plt.rcParams['axes.prop_cycle']
colors = prop_cycle.by_key()['color']

styles = {
    'rumble'   : {'color': ETHa,      'marker': 'o', 'label': 'Rumble'},
    'bigquery' : {'color': colors[6], 'marker': 's', 'label': 'BigQuery'},
}

for i, query_id in enumerate(sorted(df.query_id.unique())):
    data_g = df[df.query_id == query_id]
    label = query_id.replace('queries/query-', '')
    label = label.replace('-1', 'a').replace('-2', 'b')
    label = 'Q' + label
    ax.plot(data_g.num_events, data_g.total_slot,
            label=label)

ax.set_xlim(0.8*1000*2**0, 1000*2**14/0.8)
ax.set_xticks([2**i*1000 for i in range(15)])
ax.set_xticklabels(['1k', '', '4k', '', '', '32k', '', '', '256k', '', '', '2M', '', '', '16M'])
ax.set_ylim(0.01, 10*60)
ax.set_yticks([0.01, 0.1, 1, 10, 60, 10*60])
ax.set_yticklabels(['10ms', '.1s', '1s', '10s', '1m', '10m'])

if args.no_xaxis:
    ax.set_xticklabels([])

if args.no_yaxis:
    ax.set_yticklabels([])

if not args.no_legend:
    ax.legend(loc='center left', bbox_to_anchor=(1.02, 0.5))

plt.savefig(args.output, format='pdf', bbox_inches='tight', pad_inches=0)
plt.close()
