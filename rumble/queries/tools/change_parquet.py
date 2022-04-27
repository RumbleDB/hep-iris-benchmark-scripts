#!/usr/bin/env python3

import argparse

import pyarrow.parquet as pq

parser = argparse.ArgumentParser()
parser.add_argument('-i', '--input',  help='Input Parquet file.')
parser.add_argument('-o', '--output', help='Output Parquet file.')
parser.add_argument('-d', '--disable-dictionary', action='store_true',
                    help='Disable dictionary encoding.')
parser.add_argument('-c', '--compression', default='snappy',
                    help='Set compression algorithm.')
parser.add_argument('-n', '--num-row-groups', default=1, type=int,
                    help='Number of row groups in the output.')
args = parser.parse_args()

table = pq.read_table(args.input)
row_group_size = table.num_rows / args.num_row_groups
pq.write_table(
    table, args.output, flavor='Spark',
    row_group_size=row_group_size,
    use_dictionary=not args.disable_dictionary,
    compression=args.compression,
)
