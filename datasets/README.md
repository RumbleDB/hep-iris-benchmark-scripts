# Datasets

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
