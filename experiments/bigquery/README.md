# BigQuery

## Set-up 

Follow the instructions in the README of the git submodule under `queries` about:

1. Installation of requirements and set-up of the cloud,
1. Uploading of the native datasets from the [`dataset`](../../dataset) folder from this repository to internal and/or external storage, and
1. Running the test query to verify the set-up.

## Running experiments

1. Adapt the ID of the data set and the table name format in the first lines of [`run_experiments.sh`](./run_experiments.sh). In order to run the "pre-loaded" and "external" variants of BigQuery, adapt the table name format accordingly.
1. Possibly comment out all but one query and all but one small scale factor in the last lines of the same file for a first run.
1. To run all queries defined in the script, simply run that script:
   ```bash
   ./run_experiments.sh
   ```
   This creates a new timestamped folder inside of `experiments/`./experiments/) that contains one folder for each query execution with files related to that execution.

## Retrieving and parsing the statistics

The following two lines download additional query statistics from the cloud into the respective log folders and extract and summarize all relevant metrics from the logs.

```bash
lastexp=$(ls -d experiments/experiment_* | sort | tail -n1)
make -f $PWD/parse.mk -C $lastexp -k
```

After that, `$lastexp` is set to the log folder of the last execution of `run_experiments.sh` and `$lastexp/results.json` contains the summarized statistics. Concatenate all files that you produced this way and store the resulting file as `plots/bigquery.json` at the top level of this repository. For example:

```bash
cat "$lastexp/results.json" >> "$(git rev-parse --show-toplevel)"/plots/bigquery.json
```
