# Generating datasets

The `Makefile` in this folder downloads the original datasets and creates all
sub-sets and data formats used in the paper. In particular, it converts all
files to Parquet, once in the original ("column-shredded") format, once
converted into structured columns ("native"). The only dependency is Docker.

To produce all files, simply run:

```bash
make
```

To get a first plausibility check, run the following command:

```bash
for file in *.parquet; \
do \
  echo -ne "$file\t"; \
  (set -o pipefail; parquet-tools inspect $file | grep num_rows | cut -f2 -d:) || echo; \
done | sort -rn -k2,2 | column -t
```

This should print a list of Parquet files together with the number of rows in
each file. That number should correspond to the number encoded in the file name.
