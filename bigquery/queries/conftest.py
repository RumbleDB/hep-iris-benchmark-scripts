import glob
from os.path import dirname, join

def pytest_addoption(parser):
    parser.addoption("--query-id", action="append", default=[],
                     help="run all combinations")
    parser.addoption('-N', '--num-events', action='store',
                     help='Number of events taken from the input table. '
                          'This influences which reference file should be '
                          'taken.')
    parser.addoption('-P', '--bigquery-dataset', action='store',
                     help='Name of dataset in BigQuery.')
    parser.addoption('-I', '--input-table', action='store',
                     help='Name of input table.')
    parser.addoption('--freeze-result', action='store_true',
                     help='Overwrite reference result.')
    parser.addoption('--plot-histogram', action='store_true',
                     help='Plot resulting histogram as PNG file.')


def find_queries():
    basedir = join(dirname(__file__), 'queries')
    queryfiles = glob.glob(join(basedir, '**/query.sql'), recursive=True)
    return sorted([s[len(basedir)+1:-len('/query.sql')] for s in queryfiles])


def pytest_generate_tests(metafunc):
    if "query_id" in metafunc.fixturenames:
        queries = metafunc.config.getoption("query_id")
        queries = queries or find_queries()
        metafunc.parametrize("query_id", queries)
