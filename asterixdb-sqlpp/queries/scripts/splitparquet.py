#!/usr/bin/env python3

import argparse
import logging

from argparse_logging import add_log_level_argument
import pyarrow as pa
import pyarrow.parquet as pq

parser = argparse.ArgumentParser()
parser.add_argument('-i', '--input-file',
                    help='Path of input Parquet file.')
parser.add_argument('-p', '--output-prefix',
                    help='Path prefix of the output files (defaults to the '
                         'input file).')
parser.add_argument('-s', '--output-suffix', default='',
                    help='Additional suffix of the output files.')
add_log_level_argument(parser)
args = parser.parse_args()

if not args.output_prefix:
    args.output_prefix = args.input_file

logging.info('Opening %s.', args.input_file)
pq_file = pq.ParquetFile(args.input_file)
logging.info('Detected %i row groups.', pq_file.num_row_groups)
for i in range(pq_file.num_row_groups):
    outfile = '{}.{:03}{}'.format(args.output_prefix, i, args.output_suffix)
    logging.info('Reading row group %i/%i', i+1, pq_file.num_row_groups)
    row_group = pq_file.read_row_group(i)
    logging.info('Starting to write %s', outfile)
    pq.write_table(row_group, outfile)
