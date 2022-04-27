#!/usr/bin/env python3

import logging
from os.path import dirname, join
import sys
import time

import matplotlib; matplotlib.use('Agg')
from matplotlib import pyplot as plt
import numpy as np
import pandas as pd
import pyathena
from pyathena.pandas.util import as_pandas
from pyathena.error import OperationalError
import pytest


def test_query(query_id, pytestconfig):
    num_events = pytestconfig.getoption('num_events')
    num_events = ('-' + str(num_events)) if num_events else ''

    work_group = pytestconfig.getoption('work_group')
    staging_dir = pytestconfig.getoption('staging_dir')
    database = pytestconfig.getoption('database')
    input_table = pytestconfig.getoption('input_table')
    input_table = input_table or \
        'Run2012B_SingleMu{}'.format(num_events.replace('-','_'))

    root_dir = join(dirname(__file__))
    query_dir = join(root_dir, 'queries', query_id)
    query_file = join(query_dir, 'query.sql')
    ref_file = join(query_dir, 'ref{}.csv'.format(num_events))
    png_file = join(query_dir, 'plot{}.png'.format(num_events))

    # Read query
    with open(query_file, 'r') as f:
        query = f.read()
    query = query.format(
        input_table=input_table,
    )

    # Run query and read result
    connection = pyathena.connect(
        work_group=work_group,
        s3_staging_dir=staging_dir,
        schema_name=database,
    )

    start_timestamp = time.time()
    try:
        result = connection.cursor().execute(query)
    except pyathena.error.OperationalError as ex:
        logging.error('Query failed (OperationalError).')
        logging.error('Query ID: {}'.format(cursor.query_id))
        raise ex
    end_timestamp = time.time()

    # Trace statistics
    logging.info('Query ID: {}'.format(result.query_id))

    client_time = end_timestamp - start_timestamp
    server_time = \
        (result.completion_date_time - result.submission_date_time) \
        .total_seconds()
    data_scanned_mb = (result.data_scanned_in_bytes or float('NaN')) / 10**6
    engine_time = (result.engine_execution_time_in_millis or float('NaN')) / 1000
    service_time = (result.service_processing_time_in_millis or float('NaN')) / 1000
    planning_time = (result.query_planning_time_in_millis or float('NaN')) / 1000
    queue_time = (result.query_queue_time_in_millis or float('NaN')) / 1000
    total_time = (result.total_execution_time_in_millis or float('NaN')) / 1000

    logging.info('Client time: {:.2f}s'.format(client_time))
    logging.info('Server time: {:.2f}s'.format(server_time))
    logging.info('Data scanned: {:.2f}MB'.format(data_scanned_mb))
    logging.info('Engine time: {:.2f}s'.format(engine_time))
    logging.info('Service time: {:.2f}s'.format(service_time))
    logging.info('Planning time: {:.2f}s'.format(planning_time or float("NaN")))
    logging.info('Queue time: {:.2f}s'.format(queue_time))
    logging.info('Total time: {:.2f}s'.format(total_time))

    df = as_pandas(result)

    # Normalize query result
    df = df[df.y > 0]
    df = df[['x', 'y']]
    df.x = df.x.astype(float).round(6)
    df.y = df.y.astype(int)
    df.reset_index(drop=True, inplace=True)

    # Freeze reference result
    if pytestconfig.getoption('freeze_result'):
      df.to_csv(ref_file, index=False)

    # Read reference result
    df_ref = pd.read_csv(ref_file, dtype= {'x': float, 'y': int})

    # Plot histogram
    if pytestconfig.getoption('plot_histogram'):
      plt.hist(df.x, bins=len(df.index), weights=df.y)
      plt.savefig(png_file)

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
