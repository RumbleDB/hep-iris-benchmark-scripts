#!/usr/bin/env python3

import argparse
import matplotlib; matplotlib.use('Agg')
import numpy as np
import pandas as pd
from matplotlib import pyplot as plt

NSF1=53446198

plt.rcParams.update({
    'errorbar.capsize': 2,
    'pdf.fonttype': 42,
    'ps.fonttype': 42,
    'font.family': 'Linux Libertine',
})

def export_legend(legend, filename="legend.pdf", expand=[-5,-5,5,5]):
    fig  = legend.figure
    fig.canvas.draw()
    bbox  = legend.get_window_extent()
    bbox = bbox.from_extents(*(bbox.extents + np.array(expand)))
    bbox = bbox.transformed(fig.dpi_scale_trans.inverted())
    fig.savefig(filename, format="pdf", bbox_inches=bbox, pad_inches=0)

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
parser.add_argument('-s', '--system',    help='Which system to plot')
parser.add_argument('-L', '--legend', 	 help='Export legend',
                                         action='store_true')
parser.add_argument('-l', '--no_legend', help='Suppress legend from plot',
                                         action='store_true')
parser.add_argument('-x', '--no_xaxis',  help='Suppress x-axis from plot',
                                         action='store_true')
parser.add_argument('-y', '--no_yaxis',  help='Suppress y-axis from plot',
                                         action='store_true')
args = parser.parse_args()

df = pd.read_json(args.input, lines=True)
if args.system:
    df = df[df.system == args.system]

df.loc[df.num_cores.isna(), 'num_cores'] = 0

# Average over runs
df = df.groupby(['query_id', 'num_events', 'num_cores']).median().reset_index()

# Use largest configuration
if args.system == 'asterixdb':
    df = df[df.num_cores == 8]
else:
    df = df[df.num_cores == df.num_cores.max()]

fig = plt.figure(figsize=(2.3, 1.8))
ax = fig.add_subplot(1, 1, 1)

if not args.no_yaxis:
    ax.set_ylabel('Running time')
if not args.no_xaxis:
    ax.set_xlabel('Input size [scale factor]')

ax.set_xscale('log')
ax.set_yscale('log')

for i, query_id in enumerate(['1', '2', '3', '4', '5', '6-1', '6-2', '7', '8']):
    data_g = df[df.query_id == query_id]
    print(data_g)
    label = query_id.replace('-1', 'a').replace('-2', 'b')
    label = 'Q' + label
    ax.plot(data_g.num_events, data_g.running_time,
            label=label)

ax.set_xlim(0.8*1000*2**0, 128*NSF1/0.8)
ax.set_xticks([NSF1*2**i for i in range(-16, 8)], minor=True)
ax.set_xticklabels([''] * 34, minor=True)
ax.set_xticks([NSF1*2**i for i in range(-12, 8, 6)])
ax.set_xticklabels(['1/4Ki', '1/64', '1', '64'])
ax.set_ylim(0.01, 10*60)
ax.set_yticks([0.01, 0.1, 1, 10, 60, 10*60])
ax.set_yticklabels(['10ms', '.1s', '1s', '10s', '1m', '10m'])

if args.no_xaxis:
    ax.set_xticklabels([])

if args.no_yaxis:
    ax.set_yticklabels([])

if not args.no_legend or args.legend:
    legend = ax.legend(loc='center left', ncol=1, bbox_to_anchor=(1.25, 0.5))

if args.legend:
    export_legend(legend, args.output)
else:
    plt.savefig(args.output, format='pdf', bbox_inches='tight', pad_inches=0)
plt.close()
