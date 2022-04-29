# BigQuery

## Set-up

Follow the instructions in the README of the git submodule under `queries` about:

1. Installation of requirements and set-up of the cloud,
1. Uploading of a sample dataset to internal and/or external storage, and
1. Running the test query to verify the set-up.

## Loading the data/creating the views

1. Follow the [instructions for uploading the datasets](../../datasets) to
   cloud storage.
1. Set the `GS_*` variables in `config.sh` in the
   [`experiments/common`](../common/) folder. Then run the following script to
   create a dataset ("namespace" for tables") and the definitions of the
   external tables. These are essentially metadata operations and should run
   quickly.
   ```bash
   ./create_tables.sh
   ```
1. Next, create the external tables and load the data with the following
   script.

   Note that that script is ***not idempotent***, i.e., if you run it several
   times, for examples, after getting errors in the middle of it, it will
   silently reload more data into the existing tables such that *you end up
   with more data in the tables than desired.* If you have to rerun the script,
   delete any partially loaded tables and modify the script such that it only
   executes the loading of the non-existing tables.
   ```bash
   ./load_data.sh
   ```
   While the data is loading, the following command is useful to monitor the
   process:
   ```bash
   bq ls -j --max_results 300 --min_creation_time $(date --date="30 minutes ago" +%s)000
   ```
1. Verify that the process has completed successfully by running the following
   command (requires `jq`).
   ```bash
   ./list_tables.sh
   ```
   The `row_count` of each table should match the number of rows encoded in the
   table name (except for `65536000`, where `row_count` is `53446198`).

## Running experiments

1. Choose to run the experiments against the "external" or "pre-loaded" tabels
   by adapting the table name format in the first lines of
   [`run_experiments.sh`](./run_experiments.sh).
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
