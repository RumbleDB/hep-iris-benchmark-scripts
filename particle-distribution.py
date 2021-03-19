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

df = pd.read_csv(args.input, header=0)

# The data in this file was produced with the following query (for BigQuery):
#   WITH particle_counts AS (
#     SELECT
#       array_length(Electron) AS num_electrons,
#       array_length(Jet) AS num_jets,
#       array_length(Muon) AS num_muons
#     FROM `iris_hep_benchmark_data.Run2012B_SingleMu_65536000_view`
#   ),
#   electron_distribution AS (
#     SELECT num_electrons AS num_particles, COUNT(*) AS electrons
#     FROM particle_counts
#     GROUP BY num_electrons
#   ),
#   jet_distribution AS (
#     SELECT num_jets  AS num_particles, COUNT(*) AS jets
#     FROM particle_counts
#     GROUP BY num_jets
#   ),
#   muon_distribution AS (
#     SELECT num_muons AS num_particles, COUNT(*) AS muons
#     FROM particle_counts
#     GROUP BY num_muons
#   )
#   SELECT *
#   FROM electron_distribution
#   FULL OUTER JOIN jet_distribution USING (num_particles)
#   FULL OUTER JOIN muon_distribution USING (num_particles)
#   ORDER BY num_particles;

# Fill in num_particles with 0 particles
df_indices = pd.DataFrame(np.arange(df.num_particles.max()), columns=['num_particles'])
df = df \
    .merge(df_indices, how='outer', on=['num_particles']) \
    .sort_values(['num_particles'])
df = df.fillna(0)

total_num_events = df.muons.sum()
df['fraction_electrons'] = df.electrons / total_num_events * 100
df['fraction_jets'] = df.jets / total_num_events * 100
df['fraction_muons'] = df.muons / total_num_events * 100

fig = plt.figure(figsize=(2.3, 1.8))
ax = fig.add_subplot(1, 1, 1)

ax.set_xscale('log')
ax.set_yscale('log')

if not args.no_yaxis:
    ax.set_ylabel('Fraction of events')
if not args.no_xaxis:
    ax.set_xlabel('Number of particles')

ax.step(df.num_particles, df.fraction_electrons, label='Electrons')
ax.step(df.num_particles, df.fraction_jets, label='Jets')
ax.step(df.num_particles, df.fraction_muons, label='Muons')

ax.set_xticks([1, 10, 100])
ax.set_xticklabels(['1', '10', '100'])
ax.set_ylim(10**-6, 100)
ax.set_yticks([100, 1, .01, .0001, .000001])
ax.set_yticklabels(['100%', '1%', '.01%',
                    '$\\mathregular{10^{-4}}$%',
                    '$\\mathregular{10^{-6}}$%'])

if args.no_xaxis:
    ax.set_xticklabels([])

if args.no_yaxis:
    ax.set_yticklabels([])

if not args.no_legend:
    ax.legend(loc='center left', bbox_to_anchor=(1.02, 0.5))

plt.savefig(args.output, format='pdf', bbox_inches='tight', pad_inches=0)
plt.close()
