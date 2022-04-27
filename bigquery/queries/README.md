# High-energy Physics Analysis Queries in Google BigQuery

This repository contains implementations of High-energy Physics (HEP) analysis queries from [the IRIS HEP benchmark](https://github.com/iris-hep/adl-benchmarks-index) written in [SQL](https://en.wikipedia.org/wiki/SQL) to be run on [Google BigQuery](https://cloud.google.com/bigquery).

## Motivation

The purpose of this repository is to study the suitability of SQL for HEP analyses and to serve as a use case for improving database technologies. While SQL has often been considered unsuited for HEP analyses, we believe that the support for arrays and structured types introduced in SQL:1999 make SQL actually a rather good fit. As a high-level declarative language, it has the potential to bring many of its benefits to HEP including transparent query optimization, transparent caching, and a separation of the logical level (in the form of data model and query) from the physical level (in the form of storage formats and performance optimizations).

## Prerequisites and setup

1. Install Python 3 with pip.
1. Install the Python requirements:
   ```bash
   pip3 install -r requirements.txt
   ```
1. Create an account for [Google Cloud](https://cloud.google.com/) (you may need to set up payment information but the [free tier](https://cloud.google.com/bigquery/pricing) should be more than enough for the queries in this repository).
1. Set up a [project](https://cloud.google.com/docs/overview#projects).
1. Install [Google Cloud SDK](https://cloud.google.com/sdk/docs/install) and configure the default project (or be prepared to set up BigQuery through the web interface).

## Data

The benchmark defines a data set in the ROOT format, which is not supported by BigQuery. However, the [Rumble implementation](https://github.com/RumbleDB/hep-iris-benchmark-jsoniq) of the benchmark provides scripts to convert the data to Parquet, which BigQuery can query in-place or load into its internal representation.

Two versions are supported: "shredded objects" (where lists of particles within an event are stored as several arrays of numeric types, one for each attribute of the particles) and "native objects" (where such lists are stored as a single array of structs). Note that this only affects the data model exposed to queries; the physical representation of the two versions in Parquet is (almost) identical. Also, there is only a single set of queries, which assumes the "native objects" representation; a [view](https://en.wikipedia.org/wiki/View_(SQL)) (described below) can expose data in the "shredded objects" form as "native objects".

For convinience, this repository contains a sample of the first 1000 events of the full data set in both representations in the [`data/`](/data/) folder.

### Native Objects

#### Internal Storage

This loads the data into tables stored in BigQuery's internal storage layer.

1. Set up a bucket and upload the Parquet file(s):
   ```bash
   gsutil mb -l europe-west6 gs://my-iris-hep-bucket  # Adapt the bucket name
   gsutil cp data/*.parquet gs://my-iris-hep-bucket/
   ```
1. Create a "data set" (roughly speaking a namespace for tables):
   ```bash
   bq --location=europe-west6 mk \
       --dataset \
       --description "IRIS HEP Benchmark Data" \
       iris_hep_benchmark_data
   ```
1. Load a Parquet file into a new table:
   ```bash
   bq load \
       --source_format=PARQUET \
       iris_hep_benchmark_data.Run2012B_SingleMu_1000 \
       "gs://my-iris-hep-bucket/Run2012B_SingleMu-1000-restructured.parquet"
   ```
1. Modify the following command to reflect your data set ID and the table you just loaded, then create a view:
   ```bash
   bq mk \
       --use_legacy_sql=false \
       --view "$(sed "s/dataset_id.table_name/iris_hep_benchmark_data.Run2012B_SingleMu_1000/" view-native.sql)" \
       iris_hep_benchmark_data.Run2012B_SingleMu_1000_view
   ```

#### External Storage

This creates external tables that processes the Parquet files directly off cloud storage.

1. Set up the bucket, data set, and files as described above if you haven't done it yet.
1. Create a data definition file called `external_1000.json` with the following content:
   ```JSON
   {
     "sourceFormat": "PARQUET",
     "sourceUris": [
       "gs://my-iris-hep-bucket/Run2012B_SingleMu-1000-restructured.parquet"
     ]
   }
   ```
1. Create an external table:
   ```bash
   bq mk \
       --external_table_definition=external_1000.json \
       iris_hep_benchmark_data.Run2012B_SingleMu_restructured_external_1000
   ```
1. Create a corresponding view as described above.

### Shredded Objects

The following creates an internal table. Creating an external table works similar as described above.

1. Set up the bucket and data set above if you haven't done it yet.
1. Load a Parquet file into a new table:
   ```bash
   bq load \
       --source_format=PARQUET \
       iris_hep_benchmark_data.Run2012B_SingleMu_shredded_1000 \
       "gs://my-iris-hep-bucket/Run2012B_SingleMu-1000.parquet"
   ```
1. Modify the following command to reflect your data set ID and the table you just loaded, then create a view:
   ```bash
   bq mk \
       --use_legacy_sql=false \
       --view "$(sed "s/dataset_id.table_name/iris_hep_benchmark_data.Run2012B_SingleMu_shredded_1000/" view-shredded.sql)" \
       iris_hep_benchmark_data.Run2012B_SingleMu_shredded_1000_view
   ```

### Naming Convention for this Implementation

By default, `test_queries.py` looks for tables (or views) of the form `Run2012B_SingleMu{suffix}.parquet`, where `{suffix1}` is empty for the full data set and `_{num_events}` for a sample of `{num_events}`. A command line option allows to override the default name (see below). It also looks for reference results in `queries/{query_name}/ref{suffix2}.csv` where `{suffix2}` is empty for the full data set and `-{num_events}` for samples.

## Running Queries

Queries are run through [`test_queries.py`](/test_queries.py). Run the following command to see its options:

```
$ ./test_queries.py --help
usage: test_queries.py [options] [file_or_dir] [file_or_dir] [...]

...
custom options:
  --query-id=QUERY_ID   run all combinations
  -N NUM_EVENTS, --num-events=NUM_EVENTS
                        Number of events taken from the input table. This influences which reference file should be taken.
  -P BIGQUERY_DATASET, --bigquery-dataset=BIGQUERY_DATASET
                        Name of dataset in BigQuery.
  -I INPUT_TABLE, --input-table=INPUT_TABLE
                        Name of input table.
  --freeze-result       Overwrite reference result.
  --plot-histogram      Plot resulting histogram as PNG file.
```

For example, the following command runs queries `6-1` and `6-2` against the view for the sample of 1000 events created above:

```
./test_queries.py -vs --bigquery-dataset iris_hep_benchmark_data \
    --num-events 1000 --input-table Run2012B_SingleMu_1000_view \
    -k query-6
```
