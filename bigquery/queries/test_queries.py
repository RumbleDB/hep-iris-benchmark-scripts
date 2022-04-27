#!/usr/bin/env python3

import logging
from os.path import dirname, join
import sys
import time

from google.cloud import bigquery
import pandas as pd
import pytest


def test_query(query_id, pytestconfig):
    num_events = pytestconfig.getoption('num_events')
    num_events = ('-' + str(num_events)) if num_events else ''

    base_dir = dirname(__file__)
    query_dir = join(base_dir, 'queries', query_id)
    query_file = join(query_dir, 'query.sql')
    ref_file = join(query_dir, 'ref{}.csv'.format(num_events))
    png_file = join(query_dir, 'plot{}.png'.format(num_events))
    lib_file = join(base_dir, 'queries', 'common', 'functions.sql')

    bigquery_dataset = pytestconfig.getoption('bigquery_dataset')
    input_table = pytestconfig.getoption('input_table')
    input_table = input_table or \
        'Run2012B_SingleMu{}'.format(num_events.replace('-','_'))

    # Read query
    with open(query_file, 'r') as f:
        query = f.read()
    query = query.format(
        bigquery_dataset=bigquery_dataset,
        input_table=input_table,
    )

    # Read function library
    with open(lib_file, 'r') as f:
        lib = f.read()
    query = lib + query

    # Run query
    client = bigquery.Client()

    submission_start = time.time()
    query_job = client.query(query)
    submission_end = time.time()

    job_start = time.time()
    df = query_job.to_dataframe()
    job_end = time.time()

    # Log basic statistics
    submission_time = submission_end - submission_start
    client_time = job_end - job_start
    server_time = (query_job.ended - query_job.started).total_seconds()
    bytes_processed = query_job.total_bytes_processed

    logging.info('Job ID: {}.{}'.format(query_job.location, query_job.job_id))

    logging.info('Submission time: {:.2f}s'.format(submission_time))
    logging.info('Client time: {:.2f}s'.format(client_time))
    logging.info('Slot time: {:.2f}s'.format(query_job.slot_millis / 1000))
    logging.info('Server elapsed time: {:.2f}s'.format(server_time))
    logging.info('Megabytes processed: {:.2f}MB'.format(bytes_processed / 10**6))

    # Normalize query result
    df = df[df.y > 0]
    df = df[['x', 'y']]
    df.x = df.x.astype(float).round(6)
    df.y = df.y.astype(int)
    df.reset_index(drop=True, inplace=True)

    # Freeze reference result
    if pytestconfig.getoption('freeze_result'):
        df.to_csv(ref_file, sep=',', index=False)

    # Read reference result
    df_ref = pd.read_csv(ref_file, dtype= {'x': float, 'y': int})

    # Plot histogram
    if pytestconfig.getoption('plot_histogram'):
        from matplotlib import pyplot as plt
        plt.hist(df.x, bins=len(df.index), weights=df.y)
        plt.savefig(png_file)
        plt.close()

    # Normalize reference result
    df_ref = df_ref[df_ref.y > 0]
    df_ref = df_ref[['x', 'y']]
    df_ref.x = df_ref.x.astype(float).round(6)
    df_ref.y = df_ref.y.astype(int)
    df_ref.reset_index(drop=True, inplace=True)

    # Assert correct result
    pd.testing.assert_frame_equal(df_ref, df)


if __name__ == '__main__':
    pytest.main(sys.argv)
