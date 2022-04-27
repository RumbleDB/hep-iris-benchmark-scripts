# High-energy Physics Analysis Queries in Amazon Athena

This repository contains implementations of High-energy Physics (HEP) analysis queries from [the IRIS HEP benchmark](https://github.com/iris-hep/adl-benchmarks-index) written in [SQL](https://en.wikipedia.org/wiki/SQL) to be run on [Amazon Athena](https://aws.amazon.com/athena/).

## Motivation

The purpose of this repository is to study the suitability of SQL for HEP analyses and to serve as a use case for improving database technologies. While SQL has often been considered unsuited for HEP analyses, we believe that the support for arrays and structured types introduced in SQL:1999 make SQL actually a rather good fit. As a high-level declarative language, it has the potential to bring many of its benefits to HEP including transparent query optimization, transparent caching, and a separation of the logical level (in the form of data model and query) from the physical level (in the form of storage formats and performance optimizations).

## Prerequisites and setup

1. Install Python 3 with pip.
1. Install the Python requirements:
   ```bash
   pip3 install -r requirements.txt
   ```
1. Create an account for [AWS](https://aws.amazon.com/) (you may need to set up payment information but the [free tier](https://loud.google.com/bigquery/pricing) should be more than enough for the queries in this repository).
1. [Configure](https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-quickstart.html) the AWS CLI.

## Data

The benchmark defines a data set in the ROOT format, which is not supported by Athena. However, the [Rumble implementation](https://github.com/RumbleDB/hep-iris-benchmark-jsoniq) of the benchmark provides scripts to convert the data to Parquet, which Athena can query in-place or load into its internal representation.

Two versions are supported: "shredded objects" (where lists of particles within an event are stored as several arrays of numeric types, one for each attribute of the particles) and "native objects" (where such lists are stored as a single array of structs). Note that this only affects the data model exposed to queries; the physical representation of the two versions in Parquet is (almost) identical. Also, there is only a single set of queries, which assumes the "native objects" representation; a [view](https://en.wikipedia.org/wiki/View_(SQL)) (described below) can expose data in the "shredded objects" form as "native objects".

For convinience, this repository contains a sample of the first 1000 events of the full data set in both representations in the [`data/`](/data/) folder.

### Native Objects

1. Set up two buckets (one for the data, one as "staging" bucket) and upload the Parquet file(s):
   ```bash
   aws s3api create-bucket --region eu-west-1 --bucket my-iris-hep-bucket --create-bucket-configuration "{\"LocationConstraint\":\"eu-west-1\"}"  # Adapt the bucket name and location
   aws s3api create-bucket --region eu-west-1 --bucket my-staging-bucket  --create-bucket-configuration "{\"LocationConstraint\":\"eu-west-1\"}"  # Adapt the bucket name and location
   aws s3 cp data/Run2012B_SingleMu-restructured-1000.parquet s3://my-iris-hep-bucket/Run2012B_SingleMu_restructured_1000/Run2012B_SingleMu_restructured_1000.parquet
   aws s3 cp data/Run2012B_SingleMu-1000.parquet              s3://my-iris-hep-bucket/Run2012B_SingleMu_1000/Run2012B_SingleMu_1000.parquet
   ```
1. Create a database:
   ```bash
   aws athena start-query-execution \
       --query-string "CREATE DATABASE my_database" \
       --result-configuration "OutputLocation=s3://my-staging-bucket/"
   ```
1. Create an external table for each of the files:
   ```bash
   scripts/create_table.py \
       --table-name Run2012B_SingleMu_1000 \
       --location s3://my-iris-hep-bucket/Run2012B_SingleMu_restructured_1000/ \
       --staging-dir s3://my-staging-bucket/ \
       --database my_database \
       --variant native \
       --view-name Run2012B_SingleMu_1000_view  # ignored for "native" variant
   ```

### Shredded Data Format

It is also possible to read Parquet files where all structs are "shredded" into columns (see the [Rumble implementation](https://github.com/RumbleDB/hep-iris-benchmark-jsoniq) for details). Use a command along the following lines for that purpose:

1. Set up the two buckets and files as described above.
1. Create an external table for each of the files:
   ```bash
   scripts/create_table.py \
       --table-name Run2012B_SingleMu_1000 \
       --location s3://my-iris-hep-bucket/Run2012B_SingleMu_1000/ \
       --staging-dir s3://my-staging-bucket/ \
       --database my_database \
       --variant shredded \
       --view-name Run2012B_SingleMu_shredded_1000_view
   ```

The queries should then be run agains `Run2012B_SingleMu_shredded_1000_view` which exposes the data in the same format as the non-shredded "native" Parquet files.

### Naming Convention for this Implementation

By default, `test_queries.py` looks for tables (or views) of the form `Run2012B_SingleMu{suffix}.parquet`, where `{suffix1}` is empty for the full data set and `_{num_events}` for a sample of `{num_events}`. A command line option allows to override the default name (see below). It also looks for reference results in `queries/{query_name}/ref{suffix2}.csv` where `{suffix2}` is empty for the full data set and `-{num_events}` for samples.

## Running Queries

Queries are run through [`test_queries.py`](/test_queries.py). Run the following command to see its options:

```
$ ./test_queries.py --help
usage: test_queries.py [options] [file_or_dir] [file_or_dir] [...]

...
custom options:
  -Q QUERY_ID, --query-id=QUERY_ID
                        Folder name of query to run.
  -F, --freeze-result   Whether the results of the query should be persisted to disk.
  --plot-histogram      Plot resulting histogram as PNG file.
  -N NUM_EVENTS, --num-events=NUM_EVENTS
                        Number of events taken from the input file. This influences which reference file should be taken.
  --work-group=WORK_GROUP
                        Name of the work group to use for Athena.
  -S STAGING_DIR, --staging-dir=STAGING_DIR
                        Directory on S3 used as output location by Athena.
  -P DATABASE, --database=DATABASE
                        Name of the schema ("database") in Athena.
  -I INPUT_TABLE, --input-table=INPUT_TABLE
                        Name of input table or view.
```

For example, the following command runs queries `6-1` and `6-2` against the view for the sample of 1000 events created above:

```
./test_queries.py -vs --num-events 1000 \
    --staging-dir s3://my-staging-bucket/ \
    --database my_database \
    --input-table Run2012B_SingleMu_1000_view \
    -k query-6
```
