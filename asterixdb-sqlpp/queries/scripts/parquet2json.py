#!/usr/bin/env python3

import argparse

import pyarrow.parquet as pq

parser = argparse.ArgumentParser()
parser.add_argument('-i', '--input-file',
                    help='Path of input Parquet file.')
parser.add_argument('-o', '--output-file',
                    help='Path of output JSON lines file.')
args = parser.parse_args()

table = pq.read_table(args.input_file)
with open(args.output_file, 'w') as output_file:
    for batch in table.to_batches(2**16):
        batch \
            .to_pandas() \
            .to_json(output_file, orient='records', lines=True)
        output_file.write('\n')
