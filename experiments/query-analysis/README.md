# Query Anylsis

In Table 1 of our paper we present a set of _soft metrics_, which attempt to
summarize the user-friendliness when writing the ADL benchmark queries for each
of the analyzed languages. For this task we employ the
[`keyword_counter.py`](keyword_counter.py) script in this folder. This script
has the following parameters:

```
usage: keyword_counter.py [-h] [--extension EXTENSION] [--csv] [--avg-clauses] path

Get the soft metrics for the JSONiq queries.

positional arguments:
  path                  Path to the queries.

optional arguments:
  -h, --help            show this help message and exit
  --extension EXTENSION
                        The extension of the query files. Can be 'jq', 'sql', 'sqlpp', 'C'
  --csv                 If present, dumps the summary of each query to csv.
  --avg-clauses         If present, prints the aggregations of each statistic.
```

An example use of this script could be:

```bash
python keyword_counter.py --extension="sql" --avg-clauses "$(git rev-parse --show-toplevel)"/experiments/athena/queries/queries
```
