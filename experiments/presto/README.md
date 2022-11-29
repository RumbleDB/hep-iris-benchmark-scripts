# PrestoDB

## Set-up

Follow the [instructions](../common/README.md) for common set-up and upload the generated data sets to your S3 bucket.

Then follow the instructions in the README of the git submodule under [`queries`](queries/README.md) about:

1. Installation of Python requirements,
1. Download the Presto CLI and configure [`presto.sh`](queries/scripts/presto.sh) to use it, and
1. Optionally:
    1. Set-up of a local test environment using docker compose,
    1. Uploading of a sample dataset to HDFS in the docker environment, and
    1. Running the test query to verify the set-up.

Finally, install the Python requirements for the parsing scripts:

```bash
pip3 install -r requirements.txt
```

## Deploy and Upload

The following command deploys Presto on an EC2 instance:

```bash
./deploy.sh
```

It also creates an SSH tunnel on port `8080` into that instance such that you can run queries on it by sending them to `localhost:8080`. Test that that works:

```bash
queries/scripts/presto.sh --server localhost:8080 --execute "SELECT 42;"
# Prints: "42"
```

Now "upload" the data (i.e., create external tables of the previously uploaded files on S3) with the following command. You may want to modify the script such that it uploads only one or a few small scale factors first.

```bash
./upload.sh
```

Verify that that worked:

```bash
queries/scripts/presto.sh --server localhost:8080 --catalog hive --schema default --execute "SHOW TABLES;"
queries/scripts/presto.sh --server localhost:8080 --catalog hive --schema default --execute "SELECT CONT(*) FROM run2012b_singlemu_1000;"  # Or some other table from the previous output
queries/test_queries.py -vs --presto-server=localhost:8080 --num-events 1000 --query-id query-1  # Or some other query/scale factor
```

When you are done with this deployment, destroy all resources:

```bash
./terminate.sh
```

## Running Experiments and Extracting Measurment Data

Modify [`run_experiments.sh`](./run_experiments.sh) to run the desired subset of experiments, initially a very small one. Then execute it:

```bash
./run_experiments.sh
```

This creates files in a folder based on the current date and time in the [`experiments`](./experiments/) folder. Summarize them with the following command:

```bash
lastexp=$(find experiments/experiment_* -maxdepth 0 | sort | tail -n1)
make -C $lastexp -f $PWD/parse.mk
cat $lastexp/result.json | jq -c
```
