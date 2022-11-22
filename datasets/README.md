# Datasets

The datasets used in this repository and the corresponding paper are all
derived from the following dataset:

> CMS collaboration (2017). SingleMu primary dataset in AOD format from Run of
> 2012 (/SingleMu/Run2012B-22Jan2013-v1/AOD). CERN Open Data Portal.
> DOI: [10.7483/OPENDATA.CMS.IYVQ.1J0W](https://doi.org/10.7483/OPENDATA.CMS.IYVQ.1J0W).

The file is available via the `root://` protocol under the following URL:

> root://eospublic.cern.ch//eos/root-eos/benchmark/Run2012B_SingleMu.root

We make the files we derived available on S3 and document below how we obtained
them.

## Download our files

Our data is stored in S3 at the bucket address
[`s3://hep-adl-ethz`](https://hep-adl-ethz.s3.amazonaws.com/). In that location,
the files are stored in the following structure:

* `hep-csv/` - contains the `csv` version of the dataset.
* `hep-parquet/` - contains the `parquet` version of the dataset.
* `hep-root/` - contains the `root` versions of the dataset.

In these folders you will often see several other subdirectories:

* `native` - contains the version of the dataset where the data is readily re-structured into object for each type of particle.
* `original` - contains the original version of the dataset where the particles are completely dis-assembled into their fundamental property (one column per property)

## Generate subsets and Parquet formats

The `Makefile` in this folder downloads the original datasets and creates all
subsets (i.e., scale factor <1) and data formats used in the paper. In
particular, it converts all files to Parquet, once in the original
("column-shredded") format, once converted into structured columns ("native").

To produce all files, simply run:

```bash
make
```

To get a first plausibility check, run the following command (this requires
[`parquet-tools`](https://pypi.org/project/parquet-tools/), see
[`requirements.txt`](requirements.txt)):

```bash
for file in *.parquet; \
do \
  echo -ne "$file\t"; \
  (set -o pipefail; parquet-tools inspect $file | grep num_rows | cut -f2 -d:) || echo; \
done | sort -rn -k2,2 | column -t
```

This should print a list of Parquet files together with the number of rows in
each file. That number should correspond to the number encoded in the file name.

## Uploading to cloud storage

First upload the files generated above. Then use the intra-cloud scripts below
to create the larger scale factors as well.

### S3

Make sure you have set `S3_REGION`, `S3_INPUT_BUCKET`, and `S3_INPUT_PATH` in
`config.sh` in the [`experiments/common`](../experiments/common/) folder and
that you have installed and set up the AWS CLI. Then, run the following script:

```bash
./upload_s3.sh
```

### Cloud Storage (for BigQuery)

Make sure you have set `GS_REGION`, `GS_INPUT_BUCKET`, and `GS_INPUT_PATH` in
`config.sh` in the [`experiments/common`](../experiments/common/) folder and
that you have installed and set up `gsutils`. Then, run the following script:

```bash
./upload_gs.sh
```

### Scale factors >1

The following script makes intra-S3/intra-GS copies of the files of scale
factor 1 in order to produce the larger scale factors.

```bash
./replicate.sh
```

## Load data

Some of the systems need additional loading, creating of views, etc. The
READMEs of those systems contain the corresponding instructions.


## Readily available files

We have also stored the `root` and `parquet` files with scale factors <= 1 in S3 at the address `s3://hep-adl-ethz/artifact-evaluation/`. You can optionally use these files instead of generating your own. You'll see the following file structure under this address:

```
root/
  Run2012B_SingleMu_restructured_1000/
    Run2012B_SingleMu_restructured_1000.parquet
  ...
parquet/
  Run2012B_SingleMu_1000/
    Run2012B_SingleMu_1000.root
  ...
```