# High-energy Physics Analysis Queries on PrestoDB

This repository contains implementations of High-energy Physics (HEP) analysis queries from [the IRIS HEP benchmark](https://github.com/iris-hep/adl-benchmarks-index) written in [SQL](https://en.wikipedia.org/wiki/SQL) to be run on [PrestoDB](https://prestodb.io/).

## Motivation

The purpose of this repository is to study the suitability of SQL for HEP analyses and to serve as a use case for improving database technologies. While SQL has often been considered unsuited for HEP analyses, we believe that the support for arrays and structured types introduced in SQL:1999 make SQL actually a rather good fit. As a high-level declarative language, it has the potential to bring many of its benefits to HEP including transparent query optimization, transparent caching, and a separation of the logical level (in the form of data model and query) from the physical level (in the form of storage formats and performance optimizations).

## Prerequisites and Setup

1. Install Python 3 with pip.
1. Install the Python requirements:
   ```bash
   pip3 install -r requirements.txt
   ```
1. Install [docker](https://docs.docker.com/get-docker/) and [docker-compose](https://docs.docker.com/compose/install/).
1. Clone [this repository](https://github.com/ingomueller-net/docker-presto) and bring up the services with Docker compose.
1. Optionally download the [Presto CLI client](https://prestodb.io/docs/current/installation/cli.html) matching the version in the docker image.
1. Set up [`scripts/presto.sh`](`scripts/presto.sh`), either based on [`scripts/presto.local.sh`](`scripts/presto.local.sh`) by modifying it to point to the Presto CLI executable from the previous step, or with the following command (which uses a Presto CLI in one of the docker images):
   ```bash
   cp scripts/presto.docker.sh scripts/presto.sh
   ```

## Data

The benchmark defines a data set in the ROOT format, which is not supported by Presto. However, the [Rumble implementation](https://github.com/RumbleDB/hep-iris-benchmark-jsoniq) of the benchmark provides scripts to convert the data to Parquet, which Presto can query in-place.

### HDFS

You can run the queries against "external tables" consisting of Parquet files on HDFS. A basic HDFS installation is part of the services brought up by Docker compose. Read the instructions of that repository for details. The main steps are as follows:

1. Copy [`Run2012B_SingleMu-restructured-1000.parquet`](/data/Run2012B_SingleMu-restructured-1000.parquet) from this repository to the `data/` repository of the Docker compose project.
1. Upload it to HFDS:
   ```bash
   docker exec -it docker-presto2_namenode_1 hadoop fs -mkdir /Run2012B_SingleMu-restructured-1000/
   docker exec -it docker-presto_namenode_1 hadoop fs -put /data/Run2012B_SingleMu-restructured-1000.parquet /Run2012B_SingleMu-restructured-1000/
   ```
1. Create an external table with the provided [script](/scripts/create_table.py):
   ```bash
   scripts/create_table.py \
       --table-name Run2012B_SingleMu_1000 \
       --location hdfs://namenode/Run2012B_SingleMu-1000/ \
       --variant native \
       --view-name Run2012B_SingleMu_1000_view  # ignored for "native" variant
   ```
   Check out the help of that script in case you want to connect to Presto with non-default parameters.

### S3

You can also read the data from an S3 bucket if you run Presto in an EC2 instance with a properly configured [instance profile](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_use_switch-role-ec2_instance-profiles.html). Assume the data is uploaded to S3, use the following command to create an external table based on these files:

```bash
scripts/create_table.py \
    --table-name Run2012B_SingleMu_1000 \
    --location s3a://my_bucket/Run2012B_SingleMu_1000/ \
    --variant native \
    --view-name Run2012B_SingleMu_1000_view  # ignored for "native" variant
```

### Shredded Data Format

It is also possible to read Parquet files where all structs are "shredded" into columns (see the [Rumble implementation](https://github.com/RumbleDB/hep-iris-benchmark-jsoniq) for details). Use a command along the following lines for that purpose:

```bash
scripts/create_table.py \
    --table-name Run2012B_SingleMu_1000 \
    --location s3a://my_bucket/Run2012B_SingleMu_shredded_1000/ \
    --variant shredded \
    --view-name Run2012B_SingleMu_shredded_1000_view
```

The queries should then be run agains `Run2012B_SingleMu_shredded_1000_view` which exposes the data in the same format as the non-shredded "native" Parquet files.

## Running Queries

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
  -P PRESTO_CMD, --presto-cmd=PRESTO_CMD
                        Path to the script that runs the Presto CLI.
  -S PRESTO_SERVER, --presto-server=PRESTO_SERVER
                        URL as <host>:<port> of the Presto server.
  -C PRESTO_CATALOGUE, --presto-catalogue=PRESTO_CATALOGUE
                        Default catalogue to use in Presto.
  --presto-schema=PRESTO_SCHEMA
                        Default schema to use in Presto.
  --plot-histogram      Plot resulting histogram as PNG file.
```

For example, the following command runs queries `6-1` and `6-2` against the table created above:

```
./test_queries.py -vs --num-events 1000 --query-id query-6-1 --query-id query-6-2
```
