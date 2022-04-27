#!/usr/bin/env python3

import json
import logging
from os.path import dirname, join
import sys
import time

from matplotlib import pyplot as plt
import numpy as np
import pandas as pd
import pytest

from scripts.asterixdb import AsterixDB


@pytest.fixture(scope="function")
def asterixdb(pytestconfig):
    asterixdb_server = pytestconfig.getoption('asterixdb_server')
    asterixdb_dataverse = pytestconfig.getoption('asterixdb_dataverse')
    logging.info('Using server %s', asterixdb_server)
    logging.info('Using dataverse %s', asterixdb_dataverse)
    return AsterixDB(asterixdb_server, asterixdb_dataverse)


def test_query(query_id, pytestconfig, asterixdb):
    num_events = pytestconfig.getoption('num_events')
    num_events = ('-' + str(num_events)) if num_events else ''

    input_table = pytestconfig.getoption('input_table')
    input_table = input_table or \
        'Run2012B_SingleMu{}'.format(num_events.replace('-','_'))

    root_dir = join(dirname(__file__))
    query_dir = join(root_dir, 'queries', query_id)
    query_file = join(query_dir, 'query.sqlpp')
    ref_file = join(query_dir, 'ref{}.csv'.format(num_events))
    png_file = join(query_dir, 'plot{}.png'.format(num_events))
    lib_file = join(root_dir, 'queries', 'common', 'functions.sqlpp')

    # Read query
    with open(query_file, 'r') as f:
        query = f.read()
    query = query % {'input_table': input_table}

    # Read function library
    with open(lib_file, 'r') as f:
        lib = f.read()
    query = lib + query

    # Run query and read result
    start_timestamp = time.time()
    result = asterixdb.run(query)
    end_timestamp = time.time()

    running_time = end_timestamp - start_timestamp
    logging.info('Running time: {:.2f}s'.format(running_time))

    # Convert result
    df = pd.DataFrame \
        .from_dict(result) \
        .astype({'x': float, 'y': int})
    logging.info(df)

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
    df_ref = pd.read_csv(ref_file, dtype={'x': np.float64, 'y': np.int32})
    logging.info(df_ref)

    # Plot histogram
    if pytestconfig.getoption('plot_histogram'):
        plt.hist(df.x, bins=len(df.index), weights=df.y)
        plt.savefig(png_file)

    # Normalize reference and query result
    df_ref = df_ref[df_ref.y > 0]
    df_ref = df_ref[['x', 'y']]
    df_ref.x = df_ref.x.astype(float).round(6)
    df_ref.y = df_ref.y.astype(int)
    df_ref.reset_index(drop=True, inplace=True)

    # Assert correct result
    pd.testing.assert_frame_equal(df_ref, df)


if __name__ == '__main__':
    sys.exit(pytest.main(sys.argv))
