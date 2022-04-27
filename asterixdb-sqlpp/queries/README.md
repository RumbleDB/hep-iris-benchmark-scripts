# High-energy Physics Analysis Queries using SQL++ (AsterixDB)

This repository contains implementations of High-energy Physics (HEP) analysis queries from [the IRIS HEP benchmark](https://github.com/iris-hep/adl-benchmarks-index) written in [SQL++](https://asterixdb.apache.org/docs/0.9.6/sqlpp/manual.html) to be run on [AsterixDB](https://asterixdb.apache.org/).

## Motivation

The purpose of this repository is to study the suitability of SQL++ for HEP analyses and to serve as a use case for improving database technologies. Since SQL++ was designed to deal with semi-structured data such as JSON documents, which often has similar or more nestedness than HEP data, it seems like a promising candidate for this benchmark.

## Prerequisites and Setup

1. Install Python 3 with pip.
1. Install the Python requirements:
   ```bash
   pip3 install -r requirements.txt
   ```
1. Install [docker](https://docs.docker.com/get-docker/) and [docker-compose](https://docs.docker.com/compose/install/).
1. Clone [this repository](https://github.com/ingomueller-net/docker-asterixdb) and bring up the services with Docker compose.

## Data

The benchmark defines a data set in the ROOT format, which is not supported by AsterixDB. However, the [Rumble implementation](https://github.com/RumbleDB/hep-iris-benchmark-jsoniq) of the benchmark provides scripts to convert the data to Parquet, which AsterixDB can load or query in-place.

### HDFS

You can run the queries against "external tables" consisting of files on HDFS. A basic HDFS installation is part of the services brought up by `docker-compose`. Read the instructions of that repository for details. The main steps are as follows:

1. Copy [`Run2012B_SingleMu-restructured-1000.parquet`](/data/Run2012B_SingleMu-restructured-1000.parquet) from this repository to the `data/` repository of the Docker compose project.
1. Upload it to HFDS:
   ```bash
   docker exec -it docker-asterixdb_namenode_1 hadoop fs -mkdir /Run2012B_SingleMu-restructured-1000/
   docker exec -it docker-asterixdb_namenode_1 hadoop fs -put /data/Run2012B_SingleMu-restructured-1000.parquet /Run2012B_SingleMu-restructured-1000/
   ```
1. Create an external table with the provided [script](/scripts/create_table.py):
   ```bash
   scripts/create_table.py \
       --asterixdb-server localhost:19002 \
       --external-server hdfs://namenode:8020 \
       --external-path "/Run2012B_SingleMu-restructured-1000/*.parquet" \
       --dataset-name Run2012B_SingleMu_1000_typed_external_parquet \
       --datatype eventType \
       --file-format parquet \
       --storage-location external \
       --log-level INFO
   ```
   Other configurations of that script are discussed below.

#### External vs Internal Tables

Instead of querying files on HDFS, you can also load the data into the internal storage of AsterixDB. To do so, use `--storage-location internal` (and adapt the name of the dataset).

#### Parquet vs JSON Files

You can also query (or load) data in the JSON format (converted with [`scripts/parquet2json.py`](/scripts/parquet2json.py)). To do so, use `--file-format json` (and adapt the name of the dataset and the files).

#### Typed vs Untyped Dataset

You can create the tables either with or without specifying a schema (i.e., either with an empty open type or a closed type with all possible attributes). Use `--datatype anyType` or `--datatype eventType`, respectively (and adapt the name of the dataset).

Queries are run through [`test_queries.py`](/test_queries.py). Run the following command to see its options:

```
$ ./test_queries.py --help
usage: test_queries.py [options] [file_or_dir] [file_or_dir] [...]

...
custom options:
  -Q QUERY_ID, --query-id=QUERY_ID
                        Folder name of query to run.
  -F FREEZE_RESULT, --freeze-result=FREEZE_RESULT
                        Whether the results of the query should be persisted to disk.
  -N NUM_EVENTS, --num-events=NUM_EVENTS
                        Number of events taken from the input file. This influences which reference file should be taken.
  -I INPUT_TABLE, --input-table=INPUT_TABLE
                        Name of input table or view.
  -S ASTERIXDB_SERVER, --asterixdb-server=ASTERIXDB_SERVER
                        URL as <host>:<port> of the AsterixDB REST interface.
  -C ASTERIXDB_DATAVERSE, --asterixdb-dataverse=ASTERIXDB_DATAVERSE
                        Default dataverse to use.
  --plot-histogram      Plot resulting histogram as PNG file.
```

For example, the following command runs queries `6-1` and `6-2` against the table created above:

```bash
./test_queries.py -vs --num-events 1000 \
    --input-table Run2012B_SingleMu_1000_typed_external_parquet \
    --query-id query-6-1 --query-id query-6-2
```
