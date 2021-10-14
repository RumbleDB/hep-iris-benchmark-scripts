# Benchmark Scripts for *Evaluating Query Languages and Systems for High-Energy Physics Data*

[![DOI](https://zenodo.org/badge/DOI/10.5281/zenodo.5569049.svg)](https://doi.org/10.5281/zenodo.5569049)

This repository contains benchmarks scripts for running the implementations of High-energy Physics (HEP) analysis queries from the [IRIS HEP benchmark](https://github.com/iris-hep/adl-benchmarks-index) for various general-purpose query processing systems. The results have been published in the following paper:

Dan Graur, Ingo Müller, Mason Proffitt, Ghislain Fourny, Gordon T. Watts, Gustavo Alonso.
*Evaluating Query Languages and Systems for High-Energy Physics Data.*
In: PVLDB 15(2), 2022.
DOI: [10.14778/3489496.3489498](https://doi.org/10.14778/3489496.3489498).

Please cite both, the paper and the software, when citing in academic contexts.

## Structure of this repository

Each system in the comparison has its own directory, all with a similar structure. In particular, they import the actual query implementations from dedicated repositories (so be sure to `git clone --recursive ...`).

```
athena/
    queries/  # git submodule with query implementation
        ...
    parse.mk
    run_experiments.sh
    summarize_run.py
    ...
bigquery/
    ...
...
```

## Running experiments

The flow for running the experiments is roughly the following:

1. Follow the setup procedure of each system as explained in the respective git repositories. In particular, convert and upload the benchmark data where required.
1. For self-managed systems, start the resources on AWS EC2 using `deploy.sh` and set up or upload the data on these resources using `upload.sh` of the respective system.
1. Run queries in one of the following ways:
   * Run individual queries using the `test_queries.py` script or (similar). The `deploy.sh` of the self-managed systems open a tunnel to the deployed EC2 instances, such that you can use the local script with the cloud resources.
   * Modify and run `run_experiments.sh` to run a batch of queries and trace its results.
1. Terminate the deployed resources with `terminate.sh`.
1. Run `make -f path/to/common/make.mk -C results/results_date-of-experiment/` to parse the trace files and produce `result.json` with the statistics of all runs.
