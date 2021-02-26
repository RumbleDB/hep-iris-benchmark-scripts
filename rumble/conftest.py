import glob
from os.path import dirname, join

def pytest_addoption(parser):
    parser.addoption('-Q', '--query-id', action='append', default=[],
                     help='Folder name of query to run.')
    parser.addoption('-N', '--num-events', action='store',
                     help='Number of events taken from the input file. '
                          'This influences which reference file should be '
                          'taken.')
    parser.addoption('-I', '--input-path', action='store',
                     help='Path to input ROOT file.')
    parser.addoption('--rumble-cmd', action='store',
                     help='Path to spark-submit.')
    parser.addoption('--rumble-server', action='store',
                     help='Rumble server to connect to.')
    parser.addoption('--run-count', action='store', default=1,
                     help='Number of runs per query.')
    parser.addoption('--warmup-count', action='store', default=0,
                     help='Number of runs to be used as warmup.')
    parser.addoption('--out-file-times', action='store',
                     help='The output path where the times are appended.')
    parser.addoption('--out-file-std', action='store',
                     help='The output path where the std are appended.')
    parser.addoption('--freeze-result', action='store_true',
                     help='Overwrite reference result.')
    parser.addoption('--plot-histogram', action='store_true',
                     help='Plot resulting histogram as PNG file.')


def find_queries():
    basedir = join(dirname(__file__), 'queries')
    queryfiles = glob.glob(join(basedir, '**/query.jq'), recursive=True)
    return sorted([s[len(basedir)+1:-len('/query.jq')] for s in queryfiles])


def pytest_generate_tests(metafunc):
    if 'query_id' in metafunc.fixturenames:
        queries = metafunc.config.getoption('query_id')
        queries = queries or find_queries()
        metafunc.parametrize('query_id', queries)
