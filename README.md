# Benchmark Scripts for *Evaluating Query Languages and Systems for High-Energy Physics Data*

[![DOI](https://zenodo.org/badge/DOI/10.5281/zenodo.5569049.svg)](https://doi.org/10.5281/zenodo.5569049)

This repository contains benchmarks scripts for running the implementations of High-energy Physics (HEP) analysis queries from the [IRIS HEP benchmark](https://github.com/iris-hep/adl-benchmarks-index) for various general-purpose query processing systems. The results have been published in the following paper:

Dan Graur, Ingo Müller, Mason Proffitt, Ghislain Fourny, Gordon T. Watts, Gustavo Alonso.
*Evaluating Query Languages and Systems for High-Energy Physics Data.*
In: PVLDB 15(2), 2022.
DOI: [10.14778/3489496.3489498](https://doi.org/10.14778/3489496.3489498).

Please cite both, the paper and the software, when citing in academic contexts.

## Overview of the repository

This repository contains the scripts for producing the datasets, the scripts for
running the experiments, and the scripts for plotting the results used in the
paper mentioned above.

We recommend to get started with the scripts in the following order:

1. Get individual queries to run with the systems you are interested in using
   the small sample datasets provided for each system.

   For that purpose, look at the general instructions in the
   [`experiments`](experiments/) folder as well as the system-specific
   instructions in the subfolders of the respective systems.
1. Generate the full datasets as described in the [`datasets`](datasets/) folder
   and upload them to cloud storage and/or load them as per the system-specific
   instructions.
1. Run the actual experiments using the system-specific scripts from the
   subfolders of the respective systems.

   Running all experiments takes several days and costs at least several hundred
   dollars of cloud credits, so it's probably a good idea to start with a small
   subset, then extend them as you gain experience and confidence.
1. Re-generate the plots with the scripts in the [`plots`](plots/) folder.

   We provide the data we used for the plots in the original paper, but you can
   also copy over your own measurement data and plot that.
