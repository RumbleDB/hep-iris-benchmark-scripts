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

# Average over runs
df = df.groupby(['system', 'query_id', 'num_events']).median().reset_index()

# Extrapolate to full data set
df_max_size = df\
    .groupby(['system', 'query_id']) \
    .agg({'num_events': 'max'}) \
    .reset_index()

df = df.merge(df_max_size, on=['system', 'query_id', 'num_events'])
df['data_scanned_per_event'] = df.data_scanned / df.num_events

# Ideal numbers ---------------------------------------------------------------
# Number of particles:
#   Numbers obtained by the following query (for BigQuery):
#     SELECT
#       COUNT(*) num_events,
#       AVG(array_length(Jet)) AS avg_num_jets,
#       AVG(array_length(Muon)) AS avg_num_muons,
#       AVG(array_length(Electron)) AS avg_num_electrons
#     FROM `iris_hep_benchmark_data.Run2012B_SingleMu_65536000_view`
avg_num_repetitions = {
    'MET': 1,
    'Jet': 3.1985978684582976,
    'Muon': 1.3927870603630244,
    'Electron': 0.21459146635650236,
}

# Projections:
#   Numbers obtained by manual analysis of query code
projections = {
    '1':   ['MET.sumet'],
    '2':   ['Jet.pt'],
    '3':   ['Jet.pt', 'Jet.eta'],
    '4':   ['Jet.pt', 'MET.sumet'],
    '5':   ['MET.sumet', 'Muon.charge', 'Muon.pt', 'Muon.eta', 'Muon.phi'],
    '6-1': ['Jet.pt', 'Jet.eta', 'Jet.phi', 'Jet.mass'],
    '6-2': ['Jet.pt', 'Jet.eta', 'Jet.phi', 'Jet.mass', 'Jet.btag'],
    '7':   ['Jet.pt', 'Muon.pt', 'Electron.pt',
            'Jet.eta', 'Muon.eta', 'Electron.eta',
            'Jet.phi', 'Muon.phi', 'Electron.phi'],
    '8':   ['Muon.pt', 'Muon.eta', 'Muon.phi', 'Muon.mass', 'Muon.charge',
            'Electron.pt', 'Electron.eta', 'Electron.phi', 'Electron.mass', 'Electron.charge',
            'MET.pt', 'MET.phi'],
}

# Compressed sizes:
#   Numbers obtained from Parquet metadata on Run2012B_SingleMu_restructured_singlerowgroup_65536000.parquet:
num_events = 53446198
compressed_sizes = {
   'MET.pt':          214430587 / num_events,
   'MET.phi':         214431145 / num_events,
   'MET.sumet':       214430239 / num_events,
   'Muon.pt':         311297601 / num_events,
   'Muon.eta':        311291992 / num_events,
   'Muon.phi':        311291141 / num_events,
   'Muon.mass':        11973455 / num_events,
   'Muon.charge':      21229056 / num_events,
   'Electron.pt':      62872210 / num_events,
   'Electron.eta':     62873722 / num_events,
   'Electron.phi':     62873343 / num_events,
   'Electron.mass':    62874924 / num_events,
   'Electron.charge':  17780277 / num_events,
   'Jet.pt':          734413811 / num_events,
   'Jet.eta':         734474125 / num_events,
   'Jet.phi':         734474158 / num_events,
   'Jet.mass':        734433042 / num_events,
   'Jet.btag':        448888103 / num_events,
}

# Compute per-event sizes and add as systems
df_compr = pd.DataFrame(((q, sum(compressed_sizes[column] for column in p))
                         for q, p in projections.items()),
                        columns=['query_id', 'data_scanned_per_event'])
df_compr['system'] = 'ideal-compr'

df_uncompr = pd.DataFrame(((q, sum(avg_num_repetitions[column.split('.')[0]] * 4 for column in p))
                           for q, p in projections.items()),
                          columns=['query_id', 'data_scanned_per_event'])
df_uncompr['system'] = 'ideal-uncompr'

df = pd.concat([df, df_compr, df_uncompr], sort=False)

# Plot -----------------------------------------------------------------------
fig = plt.figure(figsize=(5.3, 1.8))
ax = fig.add_subplot(1, 1, 1)

if not args.no_yaxis:
    ax.set_ylabel('Data scanned per event [byte]')
if not args.no_xaxis:
    ax.set_xlabel('Query')

prop_cycle = plt.rcParams['axes.prop_cycle']
colors = prop_cycle.by_key()['color']

styles = {
    'athena':            {'color': 'none',    'label': 'Athena (v1)*'},
    'athena-v2':         {'color': colors[1], 'label': 'Athena (v2)*'},
    'bigquery':          {'color': colors[2], 'label': 'BigQuery'},
    'bigquery-external': {'color': colors[3], 'label': 'BigQuery (external)'},
    'presto':            {'color': colors[4], 'label': 'Presto'},
    'rumble':            {'color': ETHa,      'label': 'Rumble'},
    'ideal-compr':       {'color': colors[6], 'label': 'Ideal (compressed)'},
    'ideal-uncompr':     {'color': colors[7], 'label': 'Ideal (uncompressed)'},
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
                    data_g.data_scanned_per_event, bar_width,
                    tick_label=data_g['query_label'],
                    **styles[system])

ax.set_xticks(indexes)
ax.set_ylim(top=150)

if args.no_xaxis:
    ax.set_xticklabels([])

if args.no_yaxis:
    ax.set_yticklabels([])

if not args.no_legend:
    ax.legend(loc='lower center', ncol=3, bbox_to_anchor=(0.5, 1.02))

plt.savefig(args.output, format='pdf', bbox_inches='tight', pad_inches=0)
plt.close()
