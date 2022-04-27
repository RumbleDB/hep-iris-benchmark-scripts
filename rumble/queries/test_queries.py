#!/usr/bin/env python3

from abc import ABC, abstractmethod
import io
import json
import logging
from os.path import dirname, join
import subprocess
import sys
import time
from urllib.parse import quote_plus, urlencode
import warnings

import pandas as pd
import pytest
import requests


class RumbleProxy(ABC):
    @abstractmethod
    def run(self, query_file, variables):
        pass


class RumbleCliProxy(RumbleProxy):
    def __init__(self, cmd):
        self.cmd = cmd

    def run(self, query_file, variables):
        # Assemble command
        cmd = [self.cmd]
        for k, v in variables.items():
            cmd += ['--variable:{k}'.format(k=k), v]
        cmd += ['--query-path', query_file]

        # Run query and read result
        output = subprocess.check_output(cmd, encoding='utf-8')

        return [json.loads(line) for line in output.splitlines() if line]


class RumbleServerProxy(RumbleProxy):
    def __init__(self, server_uri):
        self.server_uri = server_uri

    def run(self, query_file, variables):
        args = {'variable:' + quote_plus(k): quote_plus(v)
                for k, v in variables.items()}
        args['query-path'] = query_file
        args_str = urlencode(args)

        query_uri = '{server_uri}?{args}'.format(
            server_uri=self.server_uri, args=args_str)
        logging.info('Running query against %s', query_uri)
        response = json.loads(requests.post(query_uri).text)

        if 'warning' in response:
            warning = json.dumps(response['warning'])
            warnings.warn(warning, RuntimeWarning)

        if 'values' in response:
            return response['values']

        if 'error-message' in response:
            raise RuntimeError(response['error-message'])

        raise RuntimeError(str(response))


@pytest.fixture
def rumble(pytestconfig):
    # Use server if provided
    server_uri = pytestconfig.getoption('rumble_server')
    if server_uri:
        logging.info('Using server at %s', server_uri)
        return RumbleServerProxy(server_uri)

    # Fall back to CLI
    rumble_cmd = pytestconfig.getoption('rumble_cmd')
    rumble_cmd = rumble_cmd or join(dirname(__file__), 'rumble.sh')
    logging.info('Using executable %s', rumble_cmd)
    return RumbleCliProxy(rumble_cmd)


def test_query(query_id, pytestconfig, rumble):
    num_events = pytestconfig.getoption('num_events')
    num_events = ('-' + str(num_events)) if num_events else ''

    root_dir = join(dirname(__file__))
    query_dir = join(root_dir, 'queries', query_id)
    query_file = join(query_dir, 'query.jq')
    ref_file = join(query_dir, 'ref{}.csv'.format(num_events))
    png_file = join(query_dir, 'plot{}.png'.format(num_events))

    # Assemble variables
    variables = {}

    restructured = '-restructured' if 'native-objects' in query_id else ''
    input_path = pytestconfig.getoption('input_path')
    input_path = input_path or \
        join(root_dir, 'data',
             'Run2012B_SingleMu{}{}.parquet'.format(restructured, num_events))
    variables['input-path'] = input_path

    # Run query and read result
    start_timestamp = time.time()
    output = rumble.run(query_file, variables)
    end_timestamp = time.time()
    df = pd.DataFrame.from_records(output)

    running_time = end_timestamp - start_timestamp
    logging.info('Running time: {:.2f}s'.format(running_time))

    # Normalize query result
    df = df[df.y > 0]
    df = df[['x', 'y']]
    df.x = df.x.astype(float).round(6)
    df.reset_index(drop=True, inplace=True)

    # Freeze reference result
    if pytestconfig.getoption('freeze_result'):
        df.to_csv(ref_file, sep=',', index=False)

    # Read reference result
    df_ref = pd.read_csv(ref_file, sep=',')

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
    df_ref.reset_index(drop=True, inplace=True)

    # Assert correct result
    pd.testing.assert_frame_equal(df_ref, df)


if __name__ == '__main__':
    pytest.main(sys.argv)
